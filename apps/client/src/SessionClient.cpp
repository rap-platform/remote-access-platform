#include "SessionClient.h"
#include <QDebug>
#include <cstring>
#include "ProtocolCodec.h"

namespace rap::client {

SessionClient::SessionClient(VideoFrameProvider *frameProvider, QObject *parent)
    : QObject(parent), frameProvider_(frameProvider) {
    connect(&socket_, &QTcpSocket::readyRead, this, &SessionClient::onReadyRead);
    connect(&socket_, &QTcpSocket::connected, this, &SessionClient::onConnected);
    connect(&socket_, &QTcpSocket::disconnected, this, &SessionClient::onDisconnected);
    connect(&socket_, &QTcpSocket::errorOccurred, this, &SessionClient::onErrorOccurred);
}

void SessionClient::connectToHost(const QString &host, uint16_t port) {
    if (socket_.state() != QAbstractSocket::UnconnectedState) {
        socket_.abort();
    }

    qInfo() << "[Client] Connecting TCP socket to host:" << host << "port:" << port;
    setStatus("Connecting to " + host + ":" + QString::number(port) + "...");
    socket_.connectToHost(host, port);
}

void SessionClient::disconnectFromHost() {
    if (socket_.isOpen()) {
        qInfo() << "[Client] Disconnecting TCP socket from host...";
        socket_.disconnectFromHost();
    }
}

void SessionClient::onConnected() {
    isConnected_ = true;
    receiveBuffer_.clear();
    receivedFrames_ = 0;
    qInfo() << "[Client] TCP socket connected successfully!";
    setStatus("Connected — Streaming desktop session");
    emit connectionStateChanged(true);
}

void SessionClient::onDisconnected() {
    isConnected_ = false;
    qInfo() << "[Client] TCP socket disconnected.";
    setStatus("Disconnected");
    emit connectionStateChanged(false);
}

void SessionClient::onErrorOccurred(QAbstractSocket::SocketError socketError) {
    Q_UNUSED(socketError);
    isConnected_ = false;
    qWarning() << "[Client] Socket Error:" << socket_.errorString();
    setStatus("Socket Error: " + socket_.errorString());
    emit connectionStateChanged(false);
}

void SessionClient::onReadyRead() {
    receiveBuffer_.append(socket_.readAll());

    while (receiveBuffer_.size() >= 28) { // 28 byte protocol header
        const uint8_t *data = reinterpret_cast<const uint8_t *>(receiveBuffer_.constData());
        size_t size = static_cast<size_t>(receiveBuffer_.size());

        auto result = rap::protocol::ProtocolCodec::decode(data, size);

        if (std::holds_alternative<rap::protocol::ParseError>(result)) {
            auto err = std::get<rap::protocol::ParseError>(result);
            if (err == rap::protocol::ParseError::IncompleteHeader ||
                err == rap::protocol::ParseError::IncompletePayload) {
                // Buffer incomplete, wait for next TCP chunk
                break;
            } else {
                // Drop corrupt byte to realign header
                receiveBuffer_.remove(0, 1);
                continue;
            }
        }

        const auto &packet = std::get<rap::protocol::Packet>(result);
        size_t totalPacketSize = 28 + packet.header.payloadSize;

        if (packet.header.type == rap::protocol::PayloadType::FrameHeader && packet.payload.size() >= 8) {
            uint32_t width = 0;
            uint32_t height = 0;
            std::memcpy(&width, packet.payload.data(), 4);
            std::memcpy(&height, packet.payload.data() + 4, 4);

            size_t expectedPixelBytes = static_cast<size_t>(width) * height * 4;
            if (width > 0 && height > 0 && packet.payload.size() >= (8 + expectedPixelBytes)) {
                const uchar *pixelPtr = reinterpret_cast<const uchar *>(packet.payload.data() + 8);
                QImage imgCopy = QImage(pixelPtr, width, height, width * 4, QImage::Format_RGBA8888).copy();
                if (frameProvider_) {
                    frameProvider_->updateFrame(imgCopy);
                    receivedFrames_++;
                }
            }
        }

        receiveBuffer_.remove(0, static_cast<qsizetype>(totalPacketSize));
    }
}

void SessionClient::setStatus(const QString &status) {
    if (statusText_ != status) {
        statusText_ = status;
        emit statusTextChanged(statusText_);
    }
}

} // namespace rap::client
