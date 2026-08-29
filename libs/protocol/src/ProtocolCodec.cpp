#include "../include/ProtocolCodec.h"

#include <cstring>

namespace rap::protocol {

static constexpr size_t HEADER_SIZE = 4 + 2 + 2 + 8 + 8 + 4; // 28 bytes

std::vector<uint8_t> ProtocolCodec::encode(PayloadType type,
                                           uint64_t sequenceNumber,
                                           uint64_t timestampMs,
                                           const std::vector<uint8_t>& payload) {
    uint32_t payloadSize = static_cast<uint32_t>(payload.size());
    std::vector<uint8_t> buffer(HEADER_SIZE + payloadSize);

    uint8_t* ptr = buffer.data();

    // Magic Header (4 bytes)
    uint32_t magic = MAGIC_HEADER;
    std::memcpy(ptr, &magic, sizeof(magic));
    ptr += sizeof(magic);

    // Version (2 bytes)
    uint16_t version = PROTOCOL_VERSION;
    std::memcpy(ptr, &version, sizeof(version));
    ptr += sizeof(version);

    // Payload Type (2 bytes)
    uint16_t typeVal = static_cast<uint16_t>(type);
    std::memcpy(ptr, &typeVal, sizeof(typeVal));
    ptr += sizeof(typeVal);

    // Sequence Number (8 bytes)
    std::memcpy(ptr, &sequenceNumber, sizeof(sequenceNumber));
    ptr += sizeof(sequenceNumber);

    // Timestamp (8 bytes)
    std::memcpy(ptr, &timestampMs, sizeof(timestampMs));
    ptr += sizeof(timestampMs);

    // Payload Size (4 bytes)
    std::memcpy(ptr, &payloadSize, sizeof(payloadSize));
    ptr += sizeof(payloadSize);

    // Payload Body
    if (!payload.empty()) {
        std::memcpy(ptr, payload.data(), payloadSize);
    }

    return buffer;
}

ParseResult ProtocolCodec::decode(const uint8_t* data, size_t size) {
    if (size < HEADER_SIZE) {
        return ParseError::IncompleteHeader;
    }

    const uint8_t* ptr = data;

    uint32_t magic = 0;
    std::memcpy(&magic, ptr, sizeof(magic));
    ptr += sizeof(magic);

    if (magic != MAGIC_HEADER) {
        return ParseError::InvalidMagicHeader;
    }

    uint16_t version = 0;
    std::memcpy(&version, ptr, sizeof(version));
    ptr += sizeof(version);

    if (version != PROTOCOL_VERSION) {
        return ParseError::UnsupportedVersion;
    }

    uint16_t typeVal = 0;
    std::memcpy(&typeVal, ptr, sizeof(typeVal));
    ptr += sizeof(typeVal);

    uint64_t sequenceNumber = 0;
    std::memcpy(&sequenceNumber, ptr, sizeof(sequenceNumber));
    ptr += sizeof(sequenceNumber);

    uint64_t timestampMs = 0;
    std::memcpy(&timestampMs, ptr, sizeof(timestampMs));
    ptr += sizeof(timestampMs);

    uint32_t payloadSize = 0;
    std::memcpy(&payloadSize, ptr, sizeof(payloadSize));
    ptr += sizeof(payloadSize);

    if (size < HEADER_SIZE + payloadSize) {
        return ParseError::IncompletePayload;
    }

    Packet packet;
    packet.header.magic = magic;
    packet.header.version = version;
    packet.header.type = static_cast<PayloadType>(typeVal);
    packet.header.sequenceNumber = sequenceNumber;
    packet.header.timestampMs = timestampMs;
    packet.header.payloadSize = payloadSize;

    if (payloadSize > 0) {
        packet.payload.resize(payloadSize);
        std::memcpy(packet.payload.data(), ptr, payloadSize);
    }

    return packet;
}

} // namespace rap::protocol
