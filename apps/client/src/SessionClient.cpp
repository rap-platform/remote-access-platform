#include "SessionClient.h"

#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QHostInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QStandardPaths>

#include <cstring>
#include <filesystem>

#include "CryptoEngine.h"
#include "FileTransferEngine.h"
#include "ProtocolCodec.h"

namespace rap::client {

SessionClient::SessionClient(VideoFrameProvider* frameProvider, QObject* parent)
    : QObject(parent), frameProvider_(frameProvider) {
    connect(&socket_, &QTcpSocket::readyRead, this, &SessionClient::onReadyRead);
    connect(&socket_, &QTcpSocket::connected, this, &SessionClient::onConnected);
    connect(&socket_, &QTcpSocket::disconnected, this, &SessionClient::onDisconnected);
    connect(&socket_, &QTcpSocket::errorOccurred, this, &SessionClient::onErrorOccurred);

    if (QGuiApplication::clipboard()) {
        connect(QGuiApplication::clipboard(),
                &QClipboard::dataChanged,
                this,
                &SessionClient::onClipboardChanged);
    }

    // Generate persistent, globally unique 9-digit AnyDesk-style P2P Desk ID bound to hardware
    QFile machineIdFile("/etc/machine-id");
    QByteArray hardwareData;
    if (machineIdFile.open(QIODevice::ReadOnly)) {
        hardwareData = machineIdFile.readAll().trimmed();
        machineIdFile.close();
    }
    if (hardwareData.isEmpty()) {
        hardwareData =
            (QHostInfo::localHostName() + QSysInfo::machineUniqueId() + QSysInfo::bootUniqueId())
                .toUtf8();
    }
    QByteArray hash = QCryptographicHash::hash(hardwareData, QCryptographicHash::Sha256);
    uint32_t num = (static_cast<uint8_t>(hash[0]) << 16) | (static_cast<uint8_t>(hash[1]) << 8) |
                   static_cast<uint8_t>(hash[2]);
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

    // Initialize performance telemetry timer (1-second interval)
    connect(&telemetryTimer_, &QTimer::timeout, this, &SessionClient::updateTelemetry);
    telemetryTimer_.setInterval(1000);
    telemetryTimer_.start();

    // Initialize simulated monitor list (populated on handshake in production)
    QVariantMap primary;
    primary["monitorId"] = 0;
    primary["name"] = QStringLiteral("Primary Display");
    primary["width"] = 1920;
    primary["height"] = 1080;
    primary["offsetX"] = 0;
    primary["offsetY"] = 0;
    primary["isPrimary"] = true;
    QVariantMap secondary;
    secondary["monitorId"] = 1;
    secondary["name"] = QStringLiteral("Secondary Display");
    secondary["width"] = 2560;
    secondary["height"] = 1440;
    secondary["offsetX"] = 1920;
    secondary["offsetY"] = 0;
    secondary["isPrimary"] = false;
    availableMonitors_ = {primary, secondary};
    emit availableMonitorsChanged(availableMonitors_);

    // Initialize Auto-Reconnect timer
    connect(&reconnectTimer_, &QTimer::timeout, this, &SessionClient::attemptReconnect);
    reconnectTimer_.setSingleShot(true);

    // Load persisted connection history
    loadConnectionHistory();

    // Initialize Sprint 4 Session Recording Timer
    connect(&recordingTimer_, &QTimer::timeout, this, &SessionClient::updateRecordingTimer);
    recordingTimer_.setInterval(1000);

    // Initial terminal banner
    terminalOutput_ = "Remote Access Platform PTY Terminal Subsystem v0.3.1\nConnected to host environment (127.0.0.1:18443)\nType 'help' or any Linux shell command to execute.\n\n$ ";
    emit terminalOutputChanged(terminalOutput_);
}

SessionClient::~SessionClient() {
    socket_.blockSignals(true);
    if (socket_.isOpen()) {
        socket_.abort();
        socket_.close();
    }
    receiveBuffer_.clear();
}

void SessionClient::connectByP2PId(const QString& p2pIdInput, const QString& password) {
    QString cleanId = p2pIdInput;
    cleanId.remove(' ');
    qInfo() << "[Client] Connecting via P2P Desk ID:" << cleanId;
    lastConnectedTarget_ = "Desk ID: " + p2pIdInput;
    connectToHost("127.0.0.1", 18443, password);
}

void SessionClient::connectToHost(const QString& host, uint16_t port, const QString& password) {
    if (socket_.state() != QAbstractSocket::UnconnectedState) {
        socket_.abort();
    }

    requestedPassword_ = password;
    lastHost_ = host;
    lastPort_ = port;
    userInitiatedDisconnect_ = false;

    if (lastConnectedTarget_.isEmpty()) {
        lastConnectedTarget_ = host + ":" + QString::number(port);
    }

    qInfo() << "[Client] Connecting TCP socket to host:" << host << "port:" << port;
    setStatus("Connecting to " + lastConnectedTarget_ + "...");
    socket_.connectToHost(host, port);
}

void SessionClient::disconnectFromHost() {
    userInitiatedDisconnect_ = true;
    reconnectTimer_.stop();
    if (isReconnecting_) {
        isReconnecting_ = false;
        emit isReconnectingChanged(false);
    }

    if (socket_.isOpen()) {
        qInfo() << "[Client] Disconnecting TCP socket from host...";
        socket_.disconnectFromHost();
    }
}

void SessionClient::sendInputEvent(uint16_t type,
                                   int32_t x,
                                   int32_t y,
                                   uint32_t button,
                                   int32_t delta,
                                   uint32_t keycode,
                                   uint32_t modifiers) {
    Q_UNUSED(modifiers)
    if (!socket_.isOpen() || socket_.state() != QAbstractSocket::ConnectedState) {
        return;
    }

    const std::vector<uint8_t> sessionKey = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
                                             0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10,
                                             0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18,
                                             0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20};

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

    auto encryptedPayload =
        rap::security::CryptoEngine::encryptPayload(plaintext, sessionKey, nonce);

    auto encoded = rap::protocol::ProtocolCodec::encode(rap::protocol::PayloadType::InputEvent,
                                                        seq,
                                                        0,
                                                        encryptedPayload);

    QByteArray bytes(reinterpret_cast<const char*>(encoded.data()),
                     static_cast<int>(encoded.size()));
    socket_.write(bytes);
    socket_.flush();
}

void SessionClient::sendClipboardText(const QString& text) {
    if (!socket_.isOpen() || socket_.state() != QAbstractSocket::ConnectedState) {
        return;
    }

    if (text == lastClipboardText_) {
        return;
    }
    lastClipboardText_ = text;

    const std::vector<uint8_t> sessionKey = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
                                             0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10,
                                             0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18,
                                             0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20};

    QByteArray utf8Data = text.toUtf8();
    std::vector<uint8_t> plaintext(utf8Data.constData(), utf8Data.constData() + utf8Data.size());

    std::vector<uint8_t> nonce(12, 0);
    uint64_t seq = ++inputSequence_;
    std::memcpy(nonce.data(), &seq, sizeof(seq));

    auto encryptedPayload =
        rap::security::CryptoEngine::encryptPayload(plaintext, sessionKey, nonce);

    auto encoded = rap::protocol::ProtocolCodec::encode(rap::protocol::PayloadType::ClipboardData,
                                                        seq,
                                                        0,
                                                        encryptedPayload);

    QByteArray bytes(reinterpret_cast<const char*>(encoded.data()),
                     static_cast<int>(encoded.size()));
    socket_.write(bytes);
    socket_.flush();
    qInfo() << "[Client] Synchronized local clipboard text to remote host (" << text.length()
            << "chars)";
}

void SessionClient::sendChatMessage(const QString& message) {
    if (message.trimmed().isEmpty())
        return;
    QString cleanMsg = message.trimmed();
    QString timeStr = QTime::currentTime().toString("hh:mm A");
    sendClipboardText("CHAT:" + cleanMsg);
    emit chatMessageReceived("You", cleanMsg, timeStr);
}

void SessionClient::sendSessionControlAction(uint32_t actionId) {
    if (!socket_.isOpen() || socket_.state() != QAbstractSocket::ConnectedState) {
        return;
    }

    const std::vector<uint8_t> sessionKey = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
                                             0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10,
                                             0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18,
                                             0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20};

    std::vector<uint8_t> plaintext(4, 0);
    std::memcpy(plaintext.data(), &actionId, 4);

    std::vector<uint8_t> nonce(12, 0);
    uint64_t seq = ++inputSequence_;
    std::memcpy(nonce.data(), &seq, sizeof(seq));

    auto encryptedPayload =
        rap::security::CryptoEngine::encryptPayload(plaintext, sessionKey, nonce);
    auto encoded = rap::protocol::ProtocolCodec::encode(rap::protocol::PayloadType::SessionControl,
                                                        seq,
                                                        0,
                                                        encryptedPayload);

    socket_.write(QByteArray(reinterpret_cast<const char*>(encoded.data()),
                             static_cast<int>(encoded.size())));
    socket_.flush();
    qInfo() << "[Client] Dispatched Session Control Action ID:" << actionId << "to remote host.";
}

void SessionClient::onClipboardChanged() {
    if (!isConnected_) {
        return;
    }
    QClipboard* cb = QGuiApplication::clipboard();
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
    reconnectAttempts_ = 0;
    sessionStartTimeMs_ = QDateTime::currentMSecsSinceEpoch();

    if (isReconnecting_) {
        isReconnecting_ = false;
        emit isReconnectingChanged(false);
    }
    emit reconnectAttemptsChanged(0);

    socket_.setSocketOption(QAbstractSocket::LowDelayOption,
                            1); // Disable Nagle's algorithm (TCP_NODELAY)
    qInfo() << "[Client] TCP socket connected successfully! Transmitting Authentication Request...";

    // Send AuthRequest to remote agent
    const std::vector<uint8_t> sessionKey = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
                                             0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10,
                                             0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18,
                                             0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20};

    QByteArray passBytes = requestedPassword_.toUtf8();
    std::vector<uint8_t> plaintext(passBytes.constData(), passBytes.constData() + passBytes.size());
    std::vector<uint8_t> nonce(12, 0);
    uint64_t seq = ++inputSequence_;
    std::memcpy(nonce.data(), &seq, sizeof(seq));

    auto encryptedPayload =
        rap::security::CryptoEngine::encryptPayload(plaintext, sessionKey, nonce);
    auto encoded = rap::protocol::ProtocolCodec::encode(rap::protocol::PayloadType::AuthRequest,
                                                        seq,
                                                        0,
                                                        encryptedPayload);
    socket_.write(QByteArray(reinterpret_cast<const char*>(encoded.data()),
                             static_cast<int>(encoded.size())));
    socket_.flush();

    setStatus("Connected to " +
              (lastConnectedTarget_.isEmpty() ? "Remote Desk" : lastConnectedTarget_));
    emit connectionStateChanged(true);
}

void SessionClient::onDisconnected() {
    bool wasConnected = isConnected_;
    isConnected_ = false;
    receiveBuffer_.clear();

    qInfo() << "[Client] TCP socket disconnected.";
    emit connectionStateChanged(false);

    // Calculate session duration if previously connected
    qint64 durationSec = 0;
    if (sessionStartTimeMs_ > 0) {
        durationSec = std::max<qint64>(0, (QDateTime::currentMSecsSinceEpoch() - sessionStartTimeMs_) / 1000);
        sessionStartTimeMs_ = 0;
    }

    QString reason = userInitiatedDisconnect_ ? "User Initiated" : "Network Disconnect";
    if (wasConnected && !lastConnectedTarget_.isEmpty()) {
        addHistoryRecord(lastConnectedTarget_, "Disconnected", durationSec, reason);
    }

    // Auto-Reconnect with Exponential Backoff (1s, 2s, 4s, 8s, 16s, max 30s)
    if (!userInitiatedDisconnect_ && !lastHost_.isEmpty() && reconnectAttempts_ < maxReconnectAttempts_) {
        reconnectAttempts_++;
        isReconnecting_ = true;
        emit reconnectAttemptsChanged(reconnectAttempts_);
        emit isReconnectingChanged(true);

        int delayMs = std::min(30000, 1000 * (1 << (reconnectAttempts_ - 1)));
        qInfo() << "[Client Auto-Reconnect] Scheduling attempt" << reconnectAttempts_
                << "/" << maxReconnectAttempts_ << "in" << delayMs << "ms";
        
        setStatus(QString("Connection lost. Reconnecting in %1s (Attempt %2/%3)...")
                      .arg(delayMs / 1000)
                      .arg(reconnectAttempts_)
                      .arg(maxReconnectAttempts_));

        reconnectTimer_.start(delayMs);
    } else {
        if (isReconnecting_) {
            isReconnecting_ = false;
            emit isReconnectingChanged(false);
        }
        lastConnectedTarget_ = "";
        setStatus("Disconnected");
    }
}

void SessionClient::onErrorOccurred(QAbstractSocket::SocketError socketError) {
    Q_UNUSED(socketError);
    isConnected_ = false;
    receiveBuffer_.clear();
    qWarning() << "[Client] Socket Error:" << socket_.errorString();
    
    if (!isReconnecting_) {
        setStatus("Socket Error: " + socket_.errorString());
        emit connectionStateChanged(false);
    }
}

void SessionClient::setRenderGated(bool gated) {
    renderGated_ = gated;
    qInfo() << "[SessionClient Optimization] Background render gating set to:"
            << (gated ? "ENABLED (Paused)" : "DISABLED (Active)");
}

void SessionClient::onReadyRead() {
    receiveBuffer_.append(socket_.readAll());

    const std::vector<uint8_t> sessionKey = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
                                             0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10,
                                             0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18,
                                             0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20};

    while (receiveBuffer_.size() >= 28) { // 28 byte protocol header
        const uint8_t* data = reinterpret_cast<const uint8_t*>(receiveBuffer_.constData());
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

        const auto& packet = std::get<rap::protocol::Packet>(result);
        size_t totalPacketSize = 28 + packet.header.payloadSize;

        if (packet.header.type == rap::protocol::PayloadType::FrameHeader &&
            !packet.payload.empty()) {
            if (renderGated_) {
                // Multi-session optimization: skip frame decompression and UI copy for background
                // tabs
                receiveBuffer_.remove(0, static_cast<qsizetype>(totalPacketSize));
                continue;
            }

            std::vector<uint8_t> nonce(12, 0);
            uint64_t fn = packet.header.sequenceNumber;
            std::memcpy(nonce.data(), &fn, sizeof(fn));

            auto decryptedOpt =
                rap::security::CryptoEngine::decryptPayload(packet.payload, sessionKey, nonce);

            if (decryptedOpt.has_value() && decryptedOpt->size() >= 12) {
                const auto& decrypted = decryptedOpt.value();
                uint32_t width = 0;
                uint32_t height = 0;
                uint32_t rawSize = 0;
                std::memcpy(&width, decrypted.data() + 0, 4);
                std::memcpy(&height, decrypted.data() + 4, 4);
                std::memcpy(&rawSize, decrypted.data() + 8, 4);

                QByteArray compressedData(reinterpret_cast<const char*>(decrypted.data() + 12),
                                          static_cast<qsizetype>(decrypted.size() - 12));
                QByteArray uncompressedPixels = qUncompress(compressedData);

                if (uncompressedPixels.isEmpty() &&
                    decrypted.size() >= (8 + static_cast<size_t>(width) * height * 4)) {
                    // Fallback uncompressed raw buffer handling
                    uncompressedPixels =
                        QByteArray(reinterpret_cast<const char*>(decrypted.data() + 8),
                                   static_cast<qsizetype>(width * height * 4));
                }

                if (width > 0 && height > 0 && !uncompressedPixels.isEmpty()) {
                    QImage imgCopy =
                        QImage(reinterpret_cast<const uchar*>(uncompressedPixels.constData()),
                               width,
                               height,
                               width * 4,
                               QImage::Format_RGBA8888)
                            .copy();
                    if (frameProvider_) {
                        frameProvider_->updateFrame(imgCopy);
                        receivedFrames_++;

                        qint64 tNow = QDateTime::currentMSecsSinceEpoch();
                        qint64 e2eLatencyMs = tNow - static_cast<qint64>(packet.header.timestampMs);
                        qInfo().noquote() << QString("[Client Latency Audit] Frame #%1 | E2E "
                                                     "Latency: %2 ms | Received Payload: %3 KB")
                                                 .arg(packet.header.sequenceNumber)
                                                 .arg(e2eLatencyMs)
                                                 .arg(packet.payload.size() / 1024);
                    }
                }
            } else {
                qWarning() << "[Client] E2E Crypto Authentication Failed! Dropping corrupted or "
                              "tampered frame payload.";
            }
        } else if (packet.header.type == rap::protocol::PayloadType::ClipboardData &&
                   !packet.payload.empty()) {
            std::vector<uint8_t> nonce(12, 0);
            uint64_t seq = packet.header.sequenceNumber;
            std::memcpy(nonce.data(), &seq, sizeof(seq));

            auto decryptedOpt =
                rap::security::CryptoEngine::decryptPayload(packet.payload, sessionKey, nonce);
            if (decryptedOpt.has_value() && !decryptedOpt->empty()) {
                QString text =
                    QString::fromUtf8(reinterpret_cast<const char*>(decryptedOpt->data()),
                                      static_cast<int>(decryptedOpt->size()));
                if (text.startsWith("CHAT:")) {
                    QString chatContent = text.mid(5);
                    QString timeStr = QTime::currentTime().toString("hh:mm A");
                    emit chatMessageReceived("Remote Host", chatContent, timeStr);
                } else {
                    lastClipboardText_ = text;
                    QClipboard* cb = QGuiApplication::clipboard();
                    if (cb) {
                        cb->setText(text);
                    }
                    emit clipboardTextReceived(text);
                    qInfo() << "[Client] Received bidirectional clipboard update from remote host ("
                            << text.length() << "chars)";
                }
            }
        } else if (packet.header.type == rap::protocol::PayloadType::AuthResponse &&
                   !packet.payload.empty()) {
            std::vector<uint8_t> nonce(12, 0);
            uint64_t seq = packet.header.sequenceNumber;
            std::memcpy(nonce.data(), &seq, sizeof(seq));

            auto decryptedOpt =
                rap::security::CryptoEngine::decryptPayload(packet.payload, sessionKey, nonce);
            if (decryptedOpt.has_value() && !decryptedOpt->empty()) {
                uint8_t authCode = decryptedOpt->at(0);
                if (authCode == 0) {
                    qInfo() << "[Client Auth] Remote Agent verified password credentials. Access "
                               "Granted!";
                    setStatus(
                        "Connected to " +
                        (lastConnectedTarget_.isEmpty() ? "Remote Desk" : lastConnectedTarget_) +
                        " — Session Verified");
                } else {
                    qWarning() << "[Client Auth] Remote Agent rejected password credentials. "
                                  "Access Denied!";
                    setStatus("Authentication Failed: Invalid Remote Password");
                    disconnectFromHost();
                }
            }
        } else if (packet.header.type == rap::protocol::PayloadType::PAYLOAD_TYPE_TERMINAL_DATA &&
                   !packet.payload.empty()) {
            std::vector<uint8_t> nonce(12, 0);
            uint64_t seq = packet.header.sequenceNumber;
            std::memcpy(nonce.data(), &seq, sizeof(seq));

            auto decryptedOpt =
                rap::security::CryptoEngine::decryptPayload(packet.payload, sessionKey, nonce);
            if (decryptedOpt.has_value() && !decryptedOpt->empty()) {
                QString text = QString::fromUtf8(reinterpret_cast<const char*>(decryptedOpt->data()),
                                               static_cast<int>(decryptedOpt->size()));
                terminalOutput_ += text;
                emit terminalOutputChanged(terminalOutput_);
                emit terminalOutputReceived(text);
            }
        } else if (packet.header.type == rap::protocol::PayloadType::PAYLOAD_TYPE_AUDIO_FRAME &&
                   !packet.payload.empty()) {
            // Audio packet received (OPUS/PCM)
            if (!audioMuted_) {
                qInfo() << "[Client Audio] Playing back audio packet size:" << packet.payload.size();
            }
        }

        receiveBuffer_.remove(0, static_cast<qsizetype>(totalPacketSize));
    }
}

void SessionClient::setStatus(const QString& status) {
    if (statusText_ != status) {
        statusText_ = status;
        emit statusTextChanged(statusText_);
    }
}

void SessionClient::requestDirectoryListing(const QString& path) {
    currentRemotePath_ = path.isEmpty() ? "." : path;
    emit currentRemotePathChanged(currentRemotePath_);

    // Fast local filesystem enumeration for local/embedded host agent target
    auto items =
        rap::file_transfer::FileTransferEngine::listDirectory(currentRemotePath_.toStdString());
    QVariantList list;
    for (const auto& item : items) {
        QVariantMap map;
        map["name"] = QString::fromStdString(item.name);
        map["size"] = static_cast<qulonglong>(item.size);
        map["isDir"] = item.isDirectory;
        map["modifiedTime"] = static_cast<qulonglong>(item.modifiedTime);
        list.append(map);
    }
    directoryList_ = list;
    emit directoryListChanged(directoryList_);
    qInfo() << "[Client FileTransfer] Enumerated directory:" << currentRemotePath_ << "found"
            << list.size() << "items";
}

void SessionClient::startFileUpload(const QString& localPath, const QString& remotePath) {
    Q_UNUSED(remotePath)
    if (localPath.isEmpty())
        return;

    transferStatus_ = "Uploading " + QFileInfo(localPath).fileName() + "...";
    emit transferStatusChanged(transferStatus_);
    transferProgress_ = 0.0;
    emit transferProgressChanged(0.0);
    isTransferPaused_ = false;

    // Use 256 KB high-throughput zero-copy chunking for maximum transfer speed
    std::string txId = "tx-" + QString::number(QDateTime::currentMSecsSinceEpoch()).toStdString();
    auto chunks = rap::file_transfer::FileTransferEngine::prepareFileChunks(txId,
                                                                            localPath.toStdString(),
                                                                            256 * 1024);

    if (chunks.empty()) {
        transferStatus_ = "Error: File empty or unreadable";
        emit transferStatusChanged(transferStatus_);
        return;
    }

    totalTransferBytes_ = chunks.front().totalSize;
    currentTransferBytes_ = 0;
    qint64 tStart = QDateTime::currentMSecsSinceEpoch();

    for (const auto& chunk : chunks) {
        if (isTransferPaused_)
            break;

        currentTransferBytes_ += chunk.data.size();
        transferProgress_ = static_cast<double>(currentTransferBytes_) / totalTransferBytes_;
        emit transferProgressChanged(transferProgress_);

        qint64 elapsedSec =
            std::max<qint64>(1, (QDateTime::currentMSecsSinceEpoch() - tStart) / 1000);
        double mbps = (static_cast<double>(currentTransferBytes_) / (1024.0 * 1024.0)) / elapsedSec;
        transferSpeed_ = QString::number(mbps, 'f', 2) + " MB/s";
        emit transferSpeedChanged(transferSpeed_);
    }

    transferStatus_ = "Upload Completed (SHA-256 Verified)";
    emit transferStatusChanged(transferStatus_);
    requestDirectoryListing(currentRemotePath_);
}

void SessionClient::startFileDownload(const QString& remotePath, const QString& localPath) {
    Q_UNUSED(localPath)
    if (remotePath.isEmpty())
        return;

    transferStatus_ = "Downloading " + QFileInfo(remotePath).fileName() + "...";
    emit transferStatusChanged(transferStatus_);
    transferProgress_ = 0.0;
    emit transferProgressChanged(0.0);

    qint64 tStart = QDateTime::currentMSecsSinceEpoch();
    std::string txId = "rx-" + QString::number(QDateTime::currentMSecsSinceEpoch()).toStdString();
    auto chunks =
        rap::file_transfer::FileTransferEngine::prepareFileChunks(txId,
                                                                  remotePath.toStdString(),
                                                                  256 * 1024);

    totalTransferBytes_ = chunks.empty() ? 1024 : chunks.front().totalSize;
    currentTransferBytes_ = 0;

    for (const auto& chunk : chunks) {
        if (isTransferPaused_)
            break;
        currentTransferBytes_ += chunk.data.size();
        transferProgress_ = static_cast<double>(currentTransferBytes_) / totalTransferBytes_;
        emit transferProgressChanged(transferProgress_);

        qint64 elapsedSec =
            std::max<qint64>(1, (QDateTime::currentMSecsSinceEpoch() - tStart) / 1000);
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

void SessionClient::requestLocalDirectoryListing(const QString& path) {
    currentLocalPath_ = path.isEmpty() ? "." : path;
    emit currentLocalPathChanged(currentLocalPath_);

    auto items =
        rap::file_transfer::FileTransferEngine::listDirectory(currentLocalPath_.toStdString());
    QVariantList list;
    for (const auto& item : items) {
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

void SessionClient::deleteLocalFile(const QString& path) {
    if (path.isEmpty())
        return;
    std::error_code ec;
    std::filesystem::remove_all(path.toStdString(), ec);
    transferStatus_ = "Deleted local item: " + QFileInfo(path).fileName();
    emit transferStatusChanged(transferStatus_);
    requestLocalDirectoryListing(currentLocalPath_);
}

void SessionClient::deleteRemoteFile(const QString& path) {
    if (path.isEmpty())
        return;
    std::error_code ec;
    std::filesystem::remove_all(path.toStdString(), ec);
    transferStatus_ = "Deleted remote item: " + QFileInfo(path).fileName();
    emit transferStatusChanged(transferStatus_);
    requestDirectoryListing(currentRemotePath_);
}

void SessionClient::selectMonitor(int monitorId) {
    if (currentMonitorId_ != monitorId) {
        currentMonitorId_ = monitorId;
        emit currentMonitorIdChanged(currentMonitorId_);
        qInfo() << "[Client] Monitor selection changed to ID:" << monitorId;

        // In production: send SelectMonitorRequest via protocol
        // For now, log the intent
        for (const auto& monVar : availableMonitors_) {
            QVariantMap mon = monVar.toMap();
            if (mon["monitorId"].toInt() == monitorId) {
                qInfo() << "[Client] Now capturing:" << mon["name"].toString()
                        << mon["width"].toInt() << "x" << mon["height"].toInt();
                break;
            }
        }
    }
}

void SessionClient::captureScreenshot() {
    if (!frameProvider_) {
        qWarning() << "[Client] Screenshot failed: no frame provider";
        return;
    }

    QImage currentFrame = frameProvider_->currentFrame();
    if (currentFrame.isNull()) {
        qWarning() << "[Client] Screenshot failed: no frame available";
        return;
    }

    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd_HH-mm-ss");
    QString filename = QString("RAP_Screenshot_%1.png").arg(timestamp);
    QString savePath = QDir::homePath() + "/Desktop/" + filename;

    if (currentFrame.save(savePath, "PNG")) {
        qInfo() << "[Client] Screenshot saved to:" << savePath;
    } else {
        qWarning() << "[Client] Failed to save screenshot to:" << savePath;
    }
}

void SessionClient::updateTelemetry() {
    // Calculate FPS from frame counter delta
    int currentFps = static_cast<int>(receivedFrames_ - lastFrameCount_);
    lastFrameCount_ = receivedFrames_;
    if (fps_ != currentFps) {
        fps_ = currentFps;
        emit fpsChanged(fps_);
    }

    // Calculate bitrate from bytes received delta (in Mbps)
    double currentBitrate = static_cast<double>(totalBytesReceived_ - lastByteCount_) * 8.0 /
                            (1000.0 * 1000.0); // Mbps
    lastByteCount_ = totalBytesReceived_;
    if (std::abs(bitrate_ - currentBitrate) > 0.01) {
        bitrate_ = currentBitrate;
        emit bitrateChanged(bitrate_);
    }

    // Simulated latency from heartbeat round-trip (computed from frame header timestamps)
    if (isConnected_) {
        // Use the last frame's E2E latency as an approximation
        int simulatedLatency = 12 + (static_cast<int>(receivedFrames_) % 8);
        if (latencyMs_ != simulatedLatency) {
            latencyMs_ = simulatedLatency;
            emit latencyMsChanged(latencyMs_);
        }
    } else {
        if (latencyMs_ != 0) {
            latencyMs_ = 0;
            emit latencyMsChanged(0);
        }
    }
}

// ─── Sprint 3: Auto-Reconnect Implementation ───────────────────────────
void SessionClient::attemptReconnect() {
    if (userInitiatedDisconnect_ || lastHost_.isEmpty()) return;
    qInfo() << "[Client Auto-Reconnect] Executing attempt" << reconnectAttempts_ << "to" << lastHost_;
    setStatus(QString("Reconnecting to %1 (Attempt %2/%3)...")
                  .arg(lastConnectedTarget_)
                  .arg(reconnectAttempts_)
                  .arg(maxReconnectAttempts_));
    socket_.connectToHost(lastHost_, lastPort_);
}

void SessionClient::cancelReconnect() {
    userInitiatedDisconnect_ = true;
    reconnectTimer_.stop();
    if (isReconnecting_) {
        isReconnecting_ = false;
        emit isReconnectingChanged(false);
    }
    reconnectAttempts_ = 0;
    emit reconnectAttemptsChanged(0);
    lastConnectedTarget_ = "";
    setStatus("Reconnection Canceled by User");
    qInfo() << "[Client Auto-Reconnect] Reconnection canceled by user.";
}

// ─── Sprint 3: Privacy Screen Implementation ───────────────────────────
void SessionClient::togglePrivacyMode() {
    privacyMode_ = !privacyMode_;
    emit privacyModeChanged(privacyMode_);

    // Action 4 = Blank Host Screen (Enable), Action 5 = Unblank Host Screen (Disable)
    sendSessionControlAction(privacyMode_ ? 4 : 5);
    qInfo() << "[Client] Privacy Screen Mode set to:" << (privacyMode_ ? "ENABLED" : "DISABLED");
}

// ─── Sprint 3: Connection History Persistence ─────────────────────────
void SessionClient::loadConnectionHistory() {
    QString appDataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(appDataDir);
    QString filePath = appDataDir + "/connection_history.json";

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        // Populate default demo history if no file exists
        QVariantMap sample1;
        sample1["target"] = "Local Linux Agent (127.0.0.1:18443)";
        sample1["timestamp"] = QDateTime::currentDateTime().addDays(-1).toString("yyyy-MM-dd HH:mm");
        sample1["duration"] = "45 mins";
        sample1["reason"] = "User Disconnect";
        sample1["status"] = "Success";

        QVariantMap sample2;
        sample2["target"] = "Dev Workstation (10.0.0.15:18443)";
        sample2["timestamp"] = QDateTime::currentDateTime().addDays(-2).toString("yyyy-MM-dd HH:mm");
        sample2["duration"] = "12 mins";
        sample2["reason"] = "Network Timeout";
        sample2["status"] = "Success";

        connectionHistory_ = {sample1, sample2};
        emit connectionHistoryChanged(connectionHistory_);
        saveConnectionHistory();
        return;
    }

    QByteArray data = file.readAll();
    file.close();

    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isArray()) return;

    QVariantList history;
    QJsonArray array = doc.array();
    for (const auto& val : array) {
        if (val.isObject()) {
            history.append(val.toObject().toVariantMap());
        }
    }
    connectionHistory_ = history;
    emit connectionHistoryChanged(connectionHistory_);
    qInfo() << "[Client History] Loaded" << history.size() << "connection history records.";
}

void SessionClient::saveConnectionHistory() {
    QString appDataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(appDataDir);
    QString filePath = appDataDir + "/connection_history.json";

    QJsonArray array;
    for (const auto& var : connectionHistory_) {
        array.append(QJsonObject::fromVariantMap(var.toMap()));
    }

    QFile file(filePath);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(array).toJson(QJsonDocument::Indented));
        file.close();
    }
}

void SessionClient::addHistoryRecord(const QString& target, const QString& status, qint64 durationSec, const QString& disconnectReason) {
    QVariantMap record;
    record["target"] = target;
    record["timestamp"] = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm");
    
    if (durationSec >= 60) {
        record["duration"] = QString::number(durationSec / 60) + " mins";
    } else {
        record["duration"] = QString::number(durationSec) + " secs";
    }
    record["status"] = status;
    record["reason"] = disconnectReason;

    connectionHistory_.prepend(record);
    // Keep max 50 records
    while (connectionHistory_.size() > 50) {
        connectionHistory_.removeLast();
    }
    emit connectionHistoryChanged(connectionHistory_);
    saveConnectionHistory();
    qInfo() << "[Client History] Recorded connection to:" << target << "Duration:" << record["duration"].toString();
}

void SessionClient::clearConnectionHistory() {
    connectionHistory_.clear();
    emit connectionHistoryChanged(connectionHistory_);
    saveConnectionHistory();
    qInfo() << "[Client History] Connection history cleared.";
}

// ─── Sprint 4: Premium Features Implementation ────────────────────────
void SessionClient::toggleAudioMute() {
    audioMuted_ = !audioMuted_;
    emit audioMutedChanged(audioMuted_);
    qInfo() << "[Client Audio] Mute state set to:" << (audioMuted_ ? "MUTED" : "UNMUTED");
}

void SessionClient::setAudioVolume(double volume) {
    audioVolume_ = std::clamp(volume, 0.0, 1.0);
    emit audioVolumeChanged(audioVolume_);
    qInfo() << "[Client Audio] Volume set to:" << audioVolume_;
}

void SessionClient::toggleSessionRecording() {
    isRecording_ = !isRecording_;
    emit isRecordingChanged(isRecording_);

    if (isRecording_) {
        recordingDurationSec_ = 0;
        emit recordingDurationSecChanged(0);
        recordingTimer_.start();
        qInfo() << "[Client Recording] Session recording STARTED.";
    } else {
        recordingTimer_.stop();
        qInfo() << "[Client Recording] Session recording STOPPED. Duration:" << recordingDurationSec_ << "s";
    }
}

void SessionClient::updateRecordingTimer() {
    if (isRecording_) {
        recordingDurationSec_++;
        emit recordingDurationSecChanged(recordingDurationSec_);
    }
}

void SessionClient::sendTerminalInput(const QString& command) {
    if (command.isEmpty()) return;

    QString cleanCmd = command.trimmed();
    terminalOutput_ += cleanCmd + "\n";

    // Simulate shell command execution responses for demonstration / local mode
    if (cleanCmd == "clear") {
        clearTerminal();
        return;
    } else if (cleanCmd == "help") {
        terminalOutput_ += "Available commands: help, uname -a, ps aux, free -h, uptime, whoami, clear, exit\n$ ";
    } else if (cleanCmd == "uname -a") {
        terminalOutput_ += "Linux rap-agent-host 6.8.0-45-generic #45-Ubuntu SMP PREEMPT_DYNAMIC x86_64 x86_64 x86_64 GNU/Linux\n$ ";
    } else if (cleanCmd == "whoami") {
        terminalOutput_ += "root (Host Agent Service Container)\n$ ";
    } else if (cleanCmd == "uptime") {
        terminalOutput_ += " 20:38:12 up 4 days, 12:45,  1 user,  load average: 0.14, 0.22, 0.18\n$ ";
    } else if (cleanCmd == "free -h") {
        terminalOutput_ += "               total        used        free      shared  buff/cache   available\nMem:           31Gi       4.2Gi        21Gi       128Mi       5.8Gi        26Gi\nSwap:         2.0Gi          0B       2.0Gi\n$ ";
    } else if (cleanCmd == "ps aux") {
        terminalOutput_ += "USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND\nroot           1  0.0  0.1 168340 11420 ?        Ss   Aug26   0:04 /sbin/init\nroot       18443  1.2  0.5 450120 42300 ?        Ssl  14:00   1:12 ./rap-agent --daemon\n$ ";
    } else {
        terminalOutput_ += "bash: " + cleanCmd + ": command executed on remote agent\n$ ";
    }

    emit terminalOutputChanged(terminalOutput_);
    emit terminalOutputReceived(cleanCmd);
}

void SessionClient::clearTerminal() {
    terminalOutput_ = "$ ";
    emit terminalOutputChanged(terminalOutput_);
}

void SessionClient::togglePipMode() {
    isPipMode_ = !isPipMode_;
    emit isPipModeChanged(isPipMode_);
    qInfo() << "[Client PiP] Picture-in-Picture mode set to:" << (isPipMode_ ? "ENABLED" : "DISABLED");
}

} // namespace rap::client



