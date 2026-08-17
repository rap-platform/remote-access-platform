#include <QCoreApplication>
#include <QDebug>
#include <QMetaObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <cstring>
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

    // Thread-safe frame delivery from capture worker thread to main TCP socket thread
    captureBackend->startCapture([&app, &clients](const rap::capture::FrameData &frame) {
        if (clients.isEmpty()) {
            return;
        }

        uint32_t w = frame.width;
        uint32_t h = frame.height;
        std::vector<uint8_t> payload;
        payload.resize(8 + frame.pixelData.size());
        std::memcpy(payload.data(), &w, 4);
        std::memcpy(payload.data() + 4, &h, 4);
        std::memcpy(payload.data() + 8, frame.pixelData.data(), frame.pixelData.size());

        auto encoded = rap::protocol::ProtocolCodec::encode(
            rap::protocol::PayloadType::FrameHeader,
            frame.frameNumber,
            frame.timestampUs / 1000,
            payload);

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
