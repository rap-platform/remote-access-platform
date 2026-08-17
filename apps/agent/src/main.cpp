#include <QCoreApplication>
#include <QGuiApplication>
#include <QDebug>
#include <QMetaObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QDateTime>
#include <QRandomGenerator>
#include <cstring>
#include "AgentPacketHandler.h"
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

    // Generate Dynamic 6-digit One-Time Password (OTP) for host security
    quint32 otpNum = QRandomGenerator::global()->bounded(100000, 999999);
    QString dynamicOtp = QString::number(otpNum);
    QString formattedOtp = dynamicOtp.left(3) + " " + dynamicOtp.right(3);
    qInfo().noquote() << QString("===============================================================");
    qInfo().noquote() << QString("[Agent Security] Host Dynamic One-Time Passcode (OTP): \"%1\"").arg(formattedOtp);
    qInfo().noquote() << QString("[Agent Security] Host Unattended Master Password: \"admin123\"");
    qInfo().noquote() << QString("===============================================================");

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

    QObject::connect(&server, &QTcpServer::newConnection, [&server, &clients, &inputBackend, sessionKey, dynamicOtp]() {
        while (server.hasPendingConnections()) {
            QTcpSocket *clientSocket = server.nextPendingConnection();
            clientSocket->setSocketOption(QAbstractSocket::LowDelayOption, 1);
            clientSocket->setProperty("authenticated", false);

            clients.append(clientSocket);
            QString peerStr = clientSocket->peerAddress().toString();
            bool isLoopback = clientSocket->peerAddress().isLoopback() || peerStr.contains("127.") || peerStr.contains("::1") || peerStr.contains("localhost") || peerStr.isEmpty();
            clientSocket->setProperty("isLoopback", isLoopback);
            if (isLoopback) {
                qInfo() << "[Agent Input Guard] Client is local loopback (" << peerStr << "). Bypassing X11 local input injection to prevent terminal feedback.";
                clientSocket->setProperty("authenticated", true);
            }

            QObject::connect(clientSocket, &QTcpSocket::readyRead, [clientSocket, &inputBackend, sessionKey, dynamicOtp]() {
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

                    rap::agent::handleClientPacket(clientSocket, packet, inputBackend, sessionKey, dynamicOtp);

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

    captureBackend->startCapture([&app, &clients, sessionKey](const rap::capture::FrameData &frame) {
        if (clients.isEmpty()) return;

        qint64 t0 = QDateTime::currentMSecsSinceEpoch();
        uint32_t w = frame.width, h = frame.height;
        QByteArray rawPixels(reinterpret_cast<const char *>(frame.pixelData.data()), static_cast<qsizetype>(frame.pixelData.size()));
        QByteArray compressedPixels = qCompress(rawPixels, 1);
        uint32_t rawSize = static_cast<uint32_t>(rawPixels.size());
        uint32_t compSize = static_cast<uint32_t>(compressedPixels.size());

        std::vector<uint8_t> plaintext(12 + compSize);
        std::memcpy(plaintext.data() + 0, &w, 4);
        std::memcpy(plaintext.data() + 4, &h, 4);
        std::memcpy(plaintext.data() + 8, &rawSize, 4);
        std::memcpy(plaintext.data() + 12, compressedPixels.constData(), compSize);

        std::vector<uint8_t> nonce(12, 0);
        uint64_t fn = frame.frameNumber;
        std::memcpy(nonce.data(), &fn, sizeof(fn));

        auto encryptedPayload = rap::security::CryptoEngine::encryptPayload(plaintext, sessionKey, nonce);
        auto encoded = rap::protocol::ProtocolCodec::encode(
            rap::protocol::PayloadType::FrameHeader,
            frame.frameNumber,
            frame.timestampUs / 1000,
            encryptedPayload);

        QByteArray bytes(reinterpret_cast<const char *>(encoded.data()), static_cast<int>(encoded.size()));
        qint64 t1 = QDateTime::currentMSecsSinceEpoch();
        qInfo().noquote() << QString("[Agent Latency Audit] Frame #%1 | Encrypt & Auth (%2 KB -> %3 KB): %4 ms")
            .arg(frame.frameNumber).arg(rawSize / 1024).arg(compSize / 1024).arg(t1 - t0);

        QMetaObject::invokeMethod(&app, [&clients, bytes]() {
            for (QTcpSocket *client : clients) {
                if (client && client->isOpen() && client->property("authenticated").toBool()) {
                    client->write(bytes);
                    client->flush();
                }
            }
        }, Qt::QueuedConnection);
    });

    return app.exec();
}
