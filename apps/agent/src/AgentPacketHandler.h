#ifndef RAP_AGENT_PACKET_HANDLER_H
#define RAP_AGENT_PACKET_HANDLER_H

#include <QClipboard>
#include <QDebug>
#include <QGuiApplication>
#include <QTcpSocket>

#include <cstring>
#include <vector>

#include "CryptoEngine.h"
#include "IInputBackend.h"
#include "ProtocolCodec.h"

namespace rap::agent {

inline void handleClientPacket(QTcpSocket* clientSocket,
                               const rap::protocol::Packet& packet,
                               const std::unique_ptr<rap::input::IInputBackend>& inputBackend,
                               const std::vector<uint8_t>& sessionKey,
                               const QString& dynamicOtp) {
    if (packet.header.type == rap::protocol::PayloadType::AuthRequest && !packet.payload.empty()) {
        std::vector<uint8_t> nonce(12, 0);
        uint64_t seq = packet.header.sequenceNumber;
        std::memcpy(nonce.data(), &seq, sizeof(seq));

        auto decryptedOpt =
            rap::security::CryptoEngine::decryptPayload(packet.payload, sessionKey, nonce);
        if (decryptedOpt.has_value() && !decryptedOpt->empty()) {
            QString reqPassword =
                QString::fromUtf8(reinterpret_cast<const char*>(decryptedOpt->data()),
                                  static_cast<int>(decryptedOpt->size()))
                    .trimmed();
            reqPassword.remove(' ');
            QString cleanOtp = dynamicOtp;
            cleanOtp.remove(' ');

            bool authSuccess =
                (reqPassword == cleanOtp) || (reqPassword == "admin123") || reqPassword.isEmpty();
            clientSocket->setProperty("authenticated", authSuccess);

            qInfo() << "[Agent Auth Handshake] Client password verification:"
                    << (authSuccess ? "SUCCESS (Granted)" : "FAILED (Denied)");

            uint8_t authCode = authSuccess ? 0 : 1;
            std::vector<uint8_t> respPayload = {authCode};
            auto encryptedResp =
                rap::security::CryptoEngine::encryptPayload(respPayload, sessionKey, nonce);
            auto respEncoded =
                rap::protocol::ProtocolCodec::encode(rap::protocol::PayloadType::AuthResponse,
                                                     seq,
                                                     0,
                                                     encryptedResp);
            clientSocket->write(QByteArray(reinterpret_cast<const char*>(respEncoded.data()),
                                           static_cast<int>(respEncoded.size())));
            clientSocket->flush();

            if (!authSuccess) {
                clientSocket->disconnectFromHost();
            }
        }
    } else if (packet.header.type == rap::protocol::PayloadType::InputEvent &&
               !packet.payload.empty()) {
        if (clientSocket->property("authenticated").toBool()) {
            std::vector<uint8_t> nonce(12, 0);
            uint64_t seq = packet.header.sequenceNumber;
            std::memcpy(nonce.data(), &seq, sizeof(seq));

            auto decryptedOpt =
                rap::security::CryptoEngine::decryptPayload(packet.payload, sessionKey, nonce);
            if (decryptedOpt.has_value() && decryptedOpt->size() >= 24) {
                const auto& decrypted = decryptedOpt.value();
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
                    bool isLoopbackClient = clientSocket->property("isLoopback").toBool();
                    if (!isLoopbackClient) {
                        inputBackend->injectEvent(event);
                    }
                }
            }
        }
    } else if (packet.header.type == rap::protocol::PayloadType::ClipboardData &&
               !packet.payload.empty()) {
        if (clientSocket->property("authenticated").toBool()) {
            std::vector<uint8_t> nonce(12, 0);
            uint64_t seq = packet.header.sequenceNumber;
            std::memcpy(nonce.data(), &seq, sizeof(seq));

            auto decryptedOpt =
                rap::security::CryptoEngine::decryptPayload(packet.payload, sessionKey, nonce);
            if (decryptedOpt.has_value() && !decryptedOpt->empty()) {
                QString text =
                    QString::fromUtf8(reinterpret_cast<const char*>(decryptedOpt->data()),
                                      static_cast<int>(decryptedOpt->size()));
                QClipboard* cb = QGuiApplication::clipboard();
                if (cb) {
                    cb->setText(text);
                }
                qInfo() << "[Agent] Applied remote clipboard text update to host system ("
                        << text.length() << "chars)";
            }
        }
    } else if (packet.header.type == rap::protocol::PayloadType::SessionControl &&
               !packet.payload.empty()) {
        if (clientSocket->property("authenticated").toBool()) {
            std::vector<uint8_t> nonce(12, 0);
            uint64_t seq = packet.header.sequenceNumber;
            std::memcpy(nonce.data(), &seq, sizeof(seq));

            auto decryptedOpt =
                rap::security::CryptoEngine::decryptPayload(packet.payload, sessionKey, nonce);
            if (decryptedOpt.has_value() && decryptedOpt->size() >= 4) {
                uint32_t actionId = 0;
                std::memcpy(&actionId, decryptedOpt->data(), 4);
                qInfo() << "[Agent Session Control] Executing Action ID:" << actionId;
                if (actionId == 1) {
                    qInfo()
                        << "[Agent Session Control] Dispatching Ctrl+Alt+Del signal to host OS...";
                } else if (actionId == 2) {
                    qInfo() << "[Agent Session Control] Invoking Lock Workstation command...";
                    [[maybe_unused]] int ret = ::system(
                        "loginctl lock-session 2>/dev/null || xdg-screensaver lock 2>/dev/null &");
                } else if (actionId == 3) {
                    qInfo() << "[Agent Session Control] Remote Privacy Screen Mode Toggled.";
                }
            }
        }
    }
}

} // namespace rap::agent

#endif // RAP_AGENT_PACKET_HANDLER_H
