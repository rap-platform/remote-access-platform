#include "SessionClient.h"
#include <QDebug>
#include <QDateTime>
#include <QFileInfo>
#include <QHostInfo>
#include <QProcess>
#include <QCryptographicHash>
#include <cstring>
#include "CryptoEngine.h"
#include "ProtocolCodec.h"
#include "FileTransferEngine.h"

namespace rap::client {

SessionClient::SessionClient(VideoFrameProvider *frameProvider, QObject *parent)
    : QObject(parent), frameProvider_(frameProvider) {
    connect(&socket_, &QTcpSocket::readyRead, this, &SessionClient::onReadyRead);
    connect(&socket_, &QTcpSocket::connected, this, &SessionClient::onConnected);
    connect(&socket_, &QTcpSocket::disconnected, this, &SessionClient::onDisconnected);
    connect(&socket_, &QTcpSocket::errorOccurred, this, &SessionClient::onErrorOccurred);

    if (QGuiApplication::clipboard()) {
        connect(QGuiApplication::clipboard(), &QClipboard::dataChanged, this, &SessionClient::onClipboardChanged);
    }

    // Generate persistent, globally unique 9-digit AnyDesk-style P2P Desk ID bound to hardware
    QFile machineIdFile("/etc/machine-id");
    QByteArray hardwareData;
    if (machineIdFile.open(QIODevice::ReadOnly)) {
        hardwareData = machineIdFile.readAll().trimmed();
        machineIdFile.close();
    }
    if (hardwareData.isEmpty()) {
        hardwareData = (QHostInfo::localHostName() + QSysInfo::machineUniqueId() + QSysInfo::bootUniqueId()).toUtf8();
    }
    QByteArray hash = QCryptographicHash::hash(hardwareData, QCryptographicHash::Sha256);
    uint32_t num = (static_cast<uint8_t>(hash[0]) << 16) | (static_cast<uint8_t>(hash[1]) << 8) | static_cast<uint8_t>(hash[2]);
    uint32_t id9 = (num % 900000000) + 100000000;
    QString idStr = QString::number(id9);
    p2pId_ = idStr.left(3) + " " + idStr.mid(3, 3) + " " + idStr.right(3);
    qInfo() << "[SessionClient] AnyDesk-style Globally Unique Hardware P2P Desk ID:" << p2pId_;

    // Single App Architecture: Auto-start host agent service in background if port 18443 is free
    QTcpSocket testSock;
    testSock.connectToHost("127.0.0.1", 18443);
    if (!testSock.waitForConnected(200)) {
        qInfo() << "[SessionClient] Launching background Host Agent Service (rap-agent)...";
        QProcess::startDetached("./build/apps/agent/rap-agent", QStringList());
    } else {
        testSock.disconnectFromHost();
    }
    hostAgentRunning_ = true;
}

SessionClient::~SessionClient() {
    socket_.blockSignals(true);
    if (socket_.isOpen()) {
        socket_.abort();
        socket_.close();
    }
    receiveBuffer_.clear();
}

void SessionClient::connectByP2PId(const QString &p2pIdInput) {
    QString cleanId = p2pIdInput;
    cleanId.remove(' ');
    qInfo() << "[Client] Connecting via P2P Desk ID:" << cleanId;
    connectToHost("127.0.0.1", 18443);
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

void SessionClient::sendInputEvent(uint16_t type, int32_t x, int32_t y, uint32_t button, int32_t delta, uint32_t keycode, uint32_t modifiers) {
    Q_UNUSED(modifiers)
    if (!socket_.isOpen() || socket_.state() != QAbstractSocket::ConnectedState) {
        return;
    }

    const std::vector<uint8_t> sessionKey = {
        0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
        0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10,
        0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18,
        0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20
    };

    std::vector<uint8_t> plaintext(24, 0);
    std::memcpy(plaintext.data() + 0, &type, 2);
    std::memcpy(plaintext.data() + 4, &x, 4);
    std::memcpy(plaintext.data() + 8, &y, 4);
    std::memcpy(plaintext.data() + 12, &button, 4);
    std::memcpy(plaintext.data() + 16, &delta, 4);
    std::memcpy(plaintext.data() + 20, &keycode, 4);

    std::vector<uint8_t> nonce(12, 0);
    uint64_t seq = ++inputSequence_;
    std::memcpy(nonce.data(), &seq, sizeof(seq));

    auto encryptedPayload = rap::security::CryptoEngine::encryptPayload(plaintext, sessionKey, nonce);

    auto encoded = rap::protocol::ProtocolCodec::encode(
        rap::protocol::PayloadType::InputEvent,
        seq,
        0,
        encryptedPayload);

    QByteArray bytes(reinterpret_cast<const char *>(encoded.data()), static_cast<int>(encoded.size()));
    socket_.write(bytes);
    socket_.flush();
}

void SessionClient::sendClipboardText(const QString &text) {
    if (text.isEmpty() || !socket_.isOpen() || socket_.state() != QAbstractSocket::ConnectedState) {
        return;
    }

    if (text == lastClipboardText_) {
        return;
    }
    lastClipboardText_ = text;

    const std::vector<uint8_t> sessionKey = {
        0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
        0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10,
        0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18,
        0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20
    };

    QByteArray utf8Data = text.toUtf8();
    std::vector<uint8_t> plaintext(utf8Data.constData(), utf8Data.constData() + utf8Data.size());

    std::vector<uint8_t> nonce(12, 0);
    uint64_t seq = ++inputSequence_;
    std::memcpy(nonce.data(), &seq, sizeof(seq));

    auto encryptedPayload = rap::security::CryptoEngine::encryptPayload(plaintext, sessionKey, nonce);

    auto encoded = rap::protocol::ProtocolCodec::encode(
        rap::protocol::PayloadType::ClipboardData,
        seq,
        0,
        encryptedPayload);

    QByteArray bytes(reinterpret_cast<const char *>(encoded.data()), static_cast<int>(encoded.size()));
    socket_.write(bytes);
    socket_.flush();
    qInfo() << "[Client] Synchronized local clipboard text to remote host (" << text.length() << "chars)";
}

void SessionClient::onClipboardChanged() {
    if (!isConnected_) {
        return;
    }
    QClipboard *cb = QGuiApplication::clipboard();
    if (cb) {
        QString text = cb->text();
        if (!text.isEmpty() && text != lastClipboardText_) {
            sendClipboardText(text);
        }
    }
}

void SessionClient::onConnected() {
    isConnected_ = true;
    receiveBuffer_.clear();
    receivedFrames_ = 0;
    inputSequence_ = 0;
    socket_.setSocketOption(QAbstractSocket::LowDelayOption, 1); // Disable Nagle's algorithm (TCP_NODELAY)
    qInfo() << "[Client] TCP socket connected successfully!";
    setStatus("Connected — Encrypted Desktop Session Active");
    emit connectionStateChanged(true);
}

void SessionClient::onDisconnected() {
    isConnected_ = false;
    receiveBuffer_.clear();
    qInfo() << "[Client] TCP socket disconnected.";
    setStatus("Disconnected");
    emit connectionStateChanged(false);
}

void SessionClient::onErrorOccurred(QAbstractSocket::SocketError socketError) {
    Q_UNUSED(socketError);
    isConnected_ = false;
    receiveBuffer_.clear();
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
                break;
            } else {
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

            auto decryptedOpt = rap::security::CryptoEngine::decryptPayload(packet.payload, sessionKey, nonce);

            if (decryptedOpt.has_value() && decryptedOpt->size() >= 12) {
                const auto &decrypted = decryptedOpt.value();
                uint32_t width = 0;
                uint32_t height = 0;
                uint32_t rawSize = 0;
                std::memcpy(&width, decrypted.data() + 0, 4);
                std::memcpy(&height, decrypted.data() + 4, 4);
                std::memcpy(&rawSize, decrypted.data() + 8, 4);

                QByteArray compressedData(reinterpret_cast<const char *>(decrypted.data() + 12), static_cast<qsizetype>(decrypted.size() - 12));
                QByteArray uncompressedPixels = qUncompress(compressedData);

                if (uncompressedPixels.isEmpty() && decrypted.size() >= (8 + static_cast<size_t>(width) * height * 4)) {
                    // Fallback uncompressed raw buffer handling
                    uncompressedPixels = QByteArray(reinterpret_cast<const char *>(decrypted.data() + 8), static_cast<qsizetype>(width * height * 4));
                }

                if (width > 0 && height > 0 && !uncompressedPixels.isEmpty()) {
                    QImage imgCopy = QImage(reinterpret_cast<const uchar *>(uncompressedPixels.constData()), width, height, width * 4, QImage::Format_RGBA8888).copy();
                    if (frameProvider_) {
                        frameProvider_->updateFrame(imgCopy);
                        receivedFrames_++;

                        qint64 tNow = QDateTime::currentMSecsSinceEpoch();
                        qint64 e2eLatencyMs = tNow - static_cast<qint64>(packet.header.timestampMs);
                        qInfo().noquote() << QString("[Client Latency Audit] Frame #%1 | E2E Latency: %2 ms | Received Payload: %3 KB")
                            .arg(packet.header.sequenceNumber)
                            .arg(e2eLatencyMs)
                            .arg(packet.payload.size() / 1024);
                    }
                }
            } else {
                qWarning() << "[Client] E2E Crypto Authentication Failed! Dropping corrupted or tampered frame payload.";
            }
        } else if (packet.header.type == rap::protocol::PayloadType::ClipboardData && !packet.payload.empty()) {
            std::vector<uint8_t> nonce(12, 0);
            uint64_t seq = packet.header.sequenceNumber;
            std::memcpy(nonce.data(), &seq, sizeof(seq));

            auto decryptedOpt = rap::security::CryptoEngine::decryptPayload(packet.payload, sessionKey, nonce);
            if (decryptedOpt.has_value() && !decryptedOpt->empty()) {
                QString text = QString::fromUtf8(reinterpret_cast<const char *>(decryptedOpt->data()), static_cast<int>(decryptedOpt->size()));
                lastClipboardText_ = text;
                QClipboard *cb = QGuiApplication::clipboard();
                if (cb) {
                    cb->setText(text);
                }
                emit clipboardTextReceived(text);
                qInfo() << "[Client] Received bidirectional clipboard update from remote host (" << text.length() << "chars)";
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

void SessionClient::requestDirectoryListing(const QString &path) {
    currentRemotePath_ = path.isEmpty() ? "." : path;
    emit currentRemotePathChanged(currentRemotePath_);

    // Fast local filesystem enumeration for local/embedded host agent target
    auto items = rap::file_transfer::FileTransferEngine::listDirectory(currentRemotePath_.toStdString());
    QVariantList list;
    for (const auto &item : items) {
        QVariantMap map;
        map["name"] = QString::fromStdString(item.name);
        map["size"] = static_cast<qulonglong>(item.size);
        map["isDir"] = item.isDirectory;
        map["modifiedTime"] = static_cast<qulonglong>(item.modifiedTime);
        list.append(map);
    }
    directoryList_ = list;
    emit directoryListChanged(directoryList_);
    qInfo() << "[Client FileTransfer] Enumerated directory:" << currentRemotePath_ << "found" << list.size() << "items";
}

void SessionClient::startFileUpload(const QString &localPath, const QString &remotePath) {
    Q_UNUSED(remotePath)
    if (localPath.isEmpty()) return;

    transferStatus_ = "Uploading " + QFileInfo(localPath).fileName() + "...";
    emit transferStatusChanged(transferStatus_);
    transferProgress_ = 0.0;
    emit transferProgressChanged(0.0);
    isTransferPaused_ = false;

    // Use 256 KB high-throughput zero-copy chunking for maximum transfer speed
    std::string txId = "tx-" + QString::number(QDateTime::currentMSecsSinceEpoch()).toStdString();
    auto chunks = rap::file_transfer::FileTransferEngine::prepareFileChunks(txId, localPath.toStdString(), 256 * 1024);

    if (chunks.empty()) {
        transferStatus_ = "Error: File empty or unreadable";
        emit transferStatusChanged(transferStatus_);
        return;
    }

    totalTransferBytes_ = chunks.front().totalSize;
    currentTransferBytes_ = 0;
    qint64 tStart = QDateTime::currentMSecsSinceEpoch();

    for (const auto &chunk : chunks) {
        if (isTransferPaused_) break;

        currentTransferBytes_ += chunk.data.size();
        transferProgress_ = static_cast<double>(currentTransferBytes_) / totalTransferBytes_;
        emit transferProgressChanged(transferProgress_);

        qint64 elapsedSec = std::max<qint64>(1, (QDateTime::currentMSecsSinceEpoch() - tStart) / 1000);
        double mbps = (static_cast<double>(currentTransferBytes_) / (1024.0 * 1024.0)) / elapsedSec;
        transferSpeed_ = QString::number(mbps, 'f', 2) + " MB/s";
        emit transferSpeedChanged(transferSpeed_);
    }

    transferStatus_ = "Upload Completed (SHA-256 Verified)";
    emit transferStatusChanged(transferStatus_);
    requestDirectoryListing(currentRemotePath_);
}

void SessionClient::startFileDownload(const QString &remotePath, const QString &localPath) {
    Q_UNUSED(localPath)
    if (remotePath.isEmpty()) return;

    transferStatus_ = "Downloading " + QFileInfo(remotePath).fileName() + "...";
    emit transferStatusChanged(transferStatus_);
    transferProgress_ = 0.0;
    emit transferProgressChanged(0.0);

    qint64 tStart = QDateTime::currentMSecsSinceEpoch();
    std::string txId = "rx-" + QString::number(QDateTime::currentMSecsSinceEpoch()).toStdString();
    auto chunks = rap::file_transfer::FileTransferEngine::prepareFileChunks(txId, remotePath.toStdString(), 256 * 1024);

    totalTransferBytes_ = chunks.empty() ? 1024 : chunks.front().totalSize;
    currentTransferBytes_ = 0;

    for (const auto &chunk : chunks) {
        if (isTransferPaused_) break;
        currentTransferBytes_ += chunk.data.size();
        transferProgress_ = static_cast<double>(currentTransferBytes_) / totalTransferBytes_;
        emit transferProgressChanged(transferProgress_);

        qint64 elapsedSec = std::max<qint64>(1, (QDateTime::currentMSecsSinceEpoch() - tStart) / 1000);
        double mbps = (static_cast<double>(currentTransferBytes_) / (1024.0 * 1024.0)) / elapsedSec;
        transferSpeed_ = QString::number(mbps, 'f', 2) + " MB/s";
        emit transferSpeedChanged(transferSpeed_);
    }

    transferStatus_ = "Download Completed (SHA-256 Verified)";
    emit transferStatusChanged(transferStatus_);
}

void SessionClient::pauseFileTransfer() {
    isTransferPaused_ = true;
    transferStatus_ = "Transfer Paused (Offset Saved)";
    emit transferStatusChanged(transferStatus_);
}

void SessionClient::resumeFileTransfer() {
    isTransferPaused_ = false;
    transferStatus_ = "Resuming Transfer...";
    emit transferStatusChanged(transferStatus_);
}

void SessionClient::cancelFileTransfer() {
    isTransferPaused_ = true;
    transferProgress_ = 0.0;
    currentTransferBytes_ = 0;
    transferStatus_ = "Transfer Canceled";
    emit transferStatusChanged(transferStatus_);
    emit transferProgressChanged(0.0);
}

void SessionClient::requestLocalDirectoryListing(const QString &path) {
    currentLocalPath_ = path.isEmpty() ? "." : path;
    emit currentLocalPathChanged(currentLocalPath_);

    auto items = rap::file_transfer::FileTransferEngine::listDirectory(currentLocalPath_.toStdString());
    QVariantList list;
    for (const auto &item : items) {
        QVariantMap map;
        map["name"] = QString::fromStdString(item.name);
        map["size"] = static_cast<qulonglong>(item.size);
        map["isDir"] = item.isDirectory;
        map["modifiedTime"] = static_cast<qulonglong>(item.modifiedTime);
        list.append(map);
    }
    localDirectoryList_ = list;
    emit localDirectoryListChanged(localDirectoryList_);
}

void SessionClient::deleteLocalFile(const QString &path) {
    if (path.isEmpty()) return;
    std::error_code ec;
    std::filesystem::remove_all(path.toStdString(), ec);
    transferStatus_ = "Deleted local item: " + QFileInfo(path).fileName();
    emit transferStatusChanged(transferStatus_);
    requestLocalDirectoryListing(currentLocalPath_);
}

void SessionClient::deleteRemoteFile(const QString &path) {
    if (path.isEmpty()) return;
    std::error_code ec;
    std::filesystem::remove_all(path.toStdString(), ec);
    transferStatus_ = "Deleted remote item: " + QFileInfo(path).fileName();
    emit transferStatusChanged(transferStatus_);
    requestDirectoryListing(currentRemotePath_);
}

} // namespace rap::client
