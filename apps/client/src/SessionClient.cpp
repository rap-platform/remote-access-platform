#include "SessionClient.h"
#include <QDebug>
#include <cstring>
#include "CryptoEngine.h"
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
    setStatus("Connected — Encrypted Desktop Session Active");
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

    const std::vector<uint8_t> sessionKey = {
        0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
        0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10,
        0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18,
        0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20
    };

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

        if (packet.header.type == rap::protocol::PayloadType::FrameHeader && !packet.payload.empty()) {
            std::vector<uint8_t> nonce(12, 0);
            uint64_t fn = packet.header.sequenceNumber;
            std::memcpy(nonce.data(), &fn, sizeof(fn));

            // Decrypt & authenticate payload via ChaCha20-Poly1305 AEAD
            auto decryptedOpt = rap::security::CryptoEngine::decryptPayload(packet.payload, sessionKey, nonce);

            if (decryptedOpt.has_value() && decryptedOpt->size() >= 8) {
                const auto &decrypted = decryptedOpt.value();
                uint32_t width = 0;
                uint32_t height = 0;
                std::memcpy(&width, decrypted.data(), 4);
                std::memcpy(&height, decrypted.data() + 4, 4);

                size_t expectedPixelBytes = static_cast<size_t>(width) * height * 4;
                if (width > 0 && height > 0 && decrypted.size() >= (8 + expectedPixelBytes)) {
                    const uchar *pixelPtr = reinterpret_cast<const uchar *>(decrypted.data() + 8);
                    QImage imgCopy = QImage(pixelPtr, width, height, width * 4, QImage::Format_RGBA8888).copy();
                    if (frameProvider_) {
                        frameProvider_->updateFrame(imgCopy);
                        receivedFrames_++;
                    }
                }
            } else {
                qWarning() << "[Client] E2E Crypto Authentication Failed! Dropping corrupted or tampered frame payload.";
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
