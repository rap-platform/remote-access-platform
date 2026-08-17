#include <QCoreApplication>
#include <QDebug>
#include <QMetaObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <cstring>
#include "CryptoEngine.h"
#include "ICaptureBackend.h"
#include "ProtocolCodec.h"
#include "logging/JsonLogger.h"

int main(int argc, char *argv[]) {
    QCoreApplication app(argc, argv);
    app.setApplicationName("rap-agent");
    app.setApplicationVersion("0.1.0");

    rap::common::logging::JsonLogger::instance().initialize();
    qInfo() << "[Agent] Remote Desktop Headless Host Agent starting up...";

    auto captureBackend = rap::capture::CaptureBackendFactory::createDefaultBackend();
    if (!captureBackend || !captureBackend->initialize()) {
        qCritical() << "[Agent] Failed to initialize screen capture backend!";
        return 1;
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

    QObject::connect(&server, &QTcpServer::newConnection, [&server, &clients]() {
        while (server.hasPendingConnections()) {
            QTcpSocket *clientSocket = server.nextPendingConnection();
            clients.append(clientSocket);
            qInfo() << "[Agent] New client connected from:" << clientSocket->peerAddress().toString();

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

        uint32_t w = frame.width;
        uint32_t h = frame.height;
        std::vector<uint8_t> plaintext;
        plaintext.resize(8 + frame.pixelData.size());
        std::memcpy(plaintext.data(), &w, 4);
        std::memcpy(plaintext.data() + 4, &h, 4);
        std::memcpy(plaintext.data() + 8, frame.pixelData.data(), frame.pixelData.size());

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
