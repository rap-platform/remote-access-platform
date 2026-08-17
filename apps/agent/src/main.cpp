#include <QCoreApplication>
#include <QDebug>
#include <QTcpServer>
#include <QTcpSocket>
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

    // Start frame capture and send encoded protocol packets to connected clients
    captureBackend->startCapture([&clients](const rap::capture::FrameData &frame) {
        if (clients.isEmpty()) {
            return;
        }

        auto encoded = rap::protocol::ProtocolCodec::encode(
            rap::protocol::PayloadType::FrameHeader,
            frame.frameNumber,
            frame.timestampUs / 1000,
            frame.pixelData);

        QByteArray bytes(reinterpret_cast<const char *>(encoded.data()), static_cast<int>(encoded.size()));

        for (QTcpSocket *client : clients) {
            if (client && client->isOpen()) {
                client->write(bytes);
                client->flush();
            }
        }
    });

    return app.exec();
}
