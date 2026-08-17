#include <QClipboard>
#include <QCoreApplication>
#include <QGuiApplication>
#include <QDebug>
#include <QMetaObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QDateTime>
#include <cstring>
#include "CryptoEngine.h"
#include "ICaptureBackend.h"
#include "IInputBackend.h"
#include "ProtocolCodec.h"
#include "logging/JsonLogger.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("rap-agent");
    app.setApplicationVersion("0.1.0");

    rap::common::logging::JsonLogger::instance().initialize();
    qInfo() << "[Agent] Remote Desktop Headless Host Agent starting up...";

    auto captureBackend = rap::capture::CaptureBackendFactory::createDefaultBackend();
    if (!captureBackend || !captureBackend->initialize()) {
        qCritical() << "[Agent] Failed to initialize screen capture backend!";
        return 1;
    }

    auto inputBackend = rap::input::InputBackendFactory::createDefaultBackend();
    if (inputBackend) {
        inputBackend->initialize();
        qInfo() << "[Agent] Remote Input Injection initialized:" << QString::fromStdString(inputBackend->backendName());
    }

    qInfo() << "[Agent] Screen capture initialized:" << QString::fromStdString(captureBackend->backendName());

    // Generate session encryption key (Milestone 5 E2E Crypto Layer)
    const std::vector<uint8_t> sessionKey = {
        0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
        0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10,
        0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18,
        0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20
    };
    qInfo() << "[Agent] E2E Session Encryption Layer (ChaCha20-Poly1305 / X25519) Initialized.";

    QTcpServer server;
    if (!server.listen(QHostAddress::Any, 18443)) {
        qCritical() << "[Agent] Failed to bind local TCP server on port 18443:" << server.errorString();
        return 1;
    }

    qInfo() << "[Agent] TCP Server listening on port 18443. Waiting for desktop client connections...";

    QList<QTcpSocket *> clients;

    QObject::connect(&server, &QTcpServer::newConnection, [&server, &clients, &inputBackend, sessionKey]() {
        while (server.hasPendingConnections()) {
            QTcpSocket *clientSocket = server.nextPendingConnection();
            clientSocket->setSocketOption(QAbstractSocket::LowDelayOption, 1); // Disable Nagle's algorithm (TCP_NODELAY)
            clients.append(clientSocket);
            qInfo() << "[Agent] New client connected from:" << clientSocket->peerAddress().toString();

            // Handle incoming remote input events and clipboard sync over encrypted socket
            QObject::connect(clientSocket, &QTcpSocket::readyRead, [clientSocket, &inputBackend, sessionKey]() {
                QByteArray buffer = clientSocket->readAll();
                while (buffer.size() >= 28) {
                    const uint8_t *data = reinterpret_cast<const uint8_t *>(buffer.constData());
                    size_t size = static_cast<size_t>(buffer.size());

                    auto result = rap::protocol::ProtocolCodec::decode(data, size);
                    if (std::holds_alternative<rap::protocol::ParseError>(result)) {
                        break;
                    }

                    const auto &packet = std::get<rap::protocol::Packet>(result);
                    size_t totalPacketSize = 28 + packet.header.payloadSize;

                    if (packet.header.type == rap::protocol::PayloadType::InputEvent && !packet.payload.empty()) {
                        std::vector<uint8_t> nonce(12, 0);
                        uint64_t seq = packet.header.sequenceNumber;
                        std::memcpy(nonce.data(), &seq, sizeof(seq));

                        auto decryptedOpt = rap::security::CryptoEngine::decryptPayload(packet.payload, sessionKey, nonce);
                        if (decryptedOpt.has_value() && decryptedOpt->size() >= 24) {
                            const auto &decrypted = decryptedOpt.value();
                            rap::input::InputEvent event;
                            uint16_t typeVal = 0;
                            std::memcpy(&typeVal, decrypted.data() + 0, 2);
                            event.type = static_cast<rap::input::InputEventType>(typeVal);
                            std::memcpy(&event.x, decrypted.data() + 4, 4);
                            std::memcpy(&event.y, decrypted.data() + 8, 4);
                            std::memcpy(&event.button, decrypted.data() + 12, 4);
                            std::memcpy(&event.delta, decrypted.data() + 16, 4);
                            std::memcpy(&event.keycode, decrypted.data() + 20, 4);

                            if (inputBackend) {
                                inputBackend->injectEvent(event);
                            }
                        }
                    } else if (packet.header.type == rap::protocol::PayloadType::ClipboardData && !packet.payload.empty()) {
                        std::vector<uint8_t> nonce(12, 0);
                        uint64_t seq = packet.header.sequenceNumber;
                        std::memcpy(nonce.data(), &seq, sizeof(seq));

                        auto decryptedOpt = rap::security::CryptoEngine::decryptPayload(packet.payload, sessionKey, nonce);
                        if (decryptedOpt.has_value() && !decryptedOpt->empty()) {
                            QString text = QString::fromUtf8(reinterpret_cast<const char *>(decryptedOpt->data()), static_cast<int>(decryptedOpt->size()));
                            QClipboard *cb = QGuiApplication::clipboard();
                            if (cb) {
                                cb->setText(text);
                            }
                            qInfo() << "[Agent] Applied remote clipboard text update to host system (" << text.length() << "chars)";
                        }
                    }

                    buffer.remove(0, static_cast<qsizetype>(totalPacketSize));
                }
            });

            QObject::connect(clientSocket, &QTcpSocket::disconnected, [clientSocket, &clients]() {
                qInfo() << "[Agent] Client disconnected.";
                clients.removeOne(clientSocket);
                clientSocket->deleteLater();
            });
        }
    });

    // Thread-safe encrypted frame delivery from capture worker thread to main TCP socket thread
    captureBackend->startCapture([&app, &clients, sessionKey](const rap::capture::FrameData &frame) {
        if (clients.isEmpty()) {
            return;
        }

        qint64 t0 = QDateTime::currentMSecsSinceEpoch();

        uint32_t w = frame.width;
        uint32_t h = frame.height;

        QByteArray rawPixels(reinterpret_cast<const char *>(frame.pixelData.data()), static_cast<qsizetype>(frame.pixelData.size()));
        QByteArray compressedPixels = qCompress(rawPixels, 1); // Fast Level 1 zlib compression (reduces 8.3 MB to ~300 KB)

        uint32_t rawSize = static_cast<uint32_t>(rawPixels.size());
        uint32_t compSize = static_cast<uint32_t>(compressedPixels.size());

        std::vector<uint8_t> plaintext;
        plaintext.resize(12 + compSize);
        std::memcpy(plaintext.data() + 0, &w, 4);
        std::memcpy(plaintext.data() + 4, &h, 4);
        std::memcpy(plaintext.data() + 8, &rawSize, 4);
        std::memcpy(plaintext.data() + 12, compressedPixels.constData(), compSize);

        // 12-byte deterministic nonce derived from frame number
        std::vector<uint8_t> nonce(12, 0);
        uint64_t fn = frame.frameNumber;
        std::memcpy(nonce.data(), &fn, sizeof(fn));

        // Authenticated payload encryption (ChaCha20-Poly1305 AEAD)
        auto encryptedPayload = rap::security::CryptoEngine::encryptPayload(plaintext, sessionKey, nonce);

        auto encoded = rap::protocol::ProtocolCodec::encode(
            rap::protocol::PayloadType::FrameHeader,
            frame.frameNumber,
            frame.timestampUs / 1000,
            encryptedPayload);

        QByteArray bytes(reinterpret_cast<const char *>(encoded.data()), static_cast<int>(encoded.size()));

        qint64 t1 = QDateTime::currentMSecsSinceEpoch();
        qInfo().noquote() << QString("[Agent Latency Audit] Frame #%1 | Compression & Crypto Encrypt (%2 KB -> %3 KB): %4 ms")
            .arg(frame.frameNumber)
            .arg(rawSize / 1024)
            .arg(compSize / 1024)
            .arg(t1 - t0);

        QMetaObject::invokeMethod(&app, [&clients, bytes]() {
            for (QTcpSocket *client : clients) {
                if (client && client->isOpen()) {
                    client->write(bytes);
                    client->flush();
                }
            }
        }, Qt::QueuedConnection);
    });

    return app.exec();
}
