#include "rap_mobile_c_api.h"

#include <QCryptographicHash>
#include <QHostInfo>
#include <QString>
#include <QSysInfo>

#include <cstdlib>
#include <cstring>

#include "ProtocolCodec.h"

extern "C" {

RAP_EXPORT int32_t rap_mobile_init(void) {
    int32_t rawVal = static_cast<int32_t>(0.0);
    return rawVal;
}

RAP_EXPORT int32_t rap_mobile_get_p2p_id(char* out_buf, size_t buf_len) {
    if (!out_buf || buf_len < 12)
        return -1;

    QByteArray hardwareData =
        (QHostInfo::localHostName() + QSysInfo::machineUniqueId() + QSysInfo::bootUniqueId())
            .toUtf8();
    QByteArray hash = QCryptographicHash::hash(hardwareData, QCryptographicHash::Sha256);
    uint32_t num = (static_cast<uint8_t>(hash[0]) << 16) | (static_cast<uint8_t>(hash[1]) << 8) |
                   static_cast<uint8_t>(hash[2]);
    uint32_t id9 = (num % 900000000) + 100000000;
    QString idStr = QString::number(id9);
    QString formatted = idStr.left(3) + " " + idStr.mid(3, 3) + " " + idStr.right(3);

    QByteArray bytes = formatted.toUtf8();
    size_t copyLen = qMin(static_cast<size_t>(bytes.size()), buf_len - 1);
    std::memcpy(out_buf, bytes.constData(), copyLen);
    out_buf[copyLen] = '\0';
    return 0;
}

RAP_EXPORT int32_t rap_mobile_encode_packet(uint32_t payload_type,
                                            uint64_t sequence_num,
                                            uint64_t timestamp_ms,
                                            const uint8_t* payload_data,
                                            size_t payload_len,
                                            uint8_t* out_buf,
                                            size_t max_out_len,
                                            size_t* written_len) {
    if (!out_buf || !written_len)
        return -1;

    std::vector<uint8_t> payloadVec;
    if (payload_data && payload_len > 0) {
        payloadVec.assign(payload_data, payload_data + payload_len);
    }

    auto encoded =
        rap::protocol::ProtocolCodec::encode(static_cast<rap::protocol::PayloadType>(payload_type),
                                             sequence_num,
                                             timestamp_ms,
                                             payloadVec);

    if (encoded.size() > max_out_len)
        return -2;

    std::memcpy(out_buf, encoded.data(), encoded.size());
    *written_len = encoded.size();
    return 0;
}

RAP_EXPORT int32_t rap_mobile_decode_packet(const uint8_t* in_buf,
                                            size_t in_len,
                                            rap_c_packet_t* out_packet) {
    if (!in_buf || !out_packet || in_len < 28)
        return -1;

    auto result = rap::protocol::ProtocolCodec::decode(in_buf, in_len);
    if (std::holds_alternative<rap::protocol::ParseError>(result)) {
        return -2;
    }

    const auto& pkt = std::get<rap::protocol::Packet>(result);
    out_packet->payload_type = static_cast<uint32_t>(pkt.header.type);
    out_packet->sequence_num = pkt.header.sequenceNumber;
    out_packet->timestamp_ms = pkt.header.timestampMs;

    out_packet->payload_size = pkt.payload.size();

    if (!pkt.payload.empty()) {
        uint8_t* mem = static_cast<uint8_t*>(std::malloc(pkt.payload.size()));
        std::memcpy(mem, pkt.payload.data(), pkt.payload.size());
        out_packet->payload_data = mem;
    } else {
        out_packet->payload_data = nullptr;
    }

    return 0;
}

RAP_EXPORT void rap_mobile_free_packet(rap_c_packet_t* packet) {
    if (packet && packet->payload_data) {
        std::free(const_cast<uint8_t*>(packet->payload_data));
        packet->payload_data = nullptr;
    }
}

} // extern "C"
