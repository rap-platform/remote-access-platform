#ifndef RAP_PROTOCOL_CODEC_H
#define RAP_PROTOCOL_CODEC_H

#include <cstdint>
#include <string>
#include <variant>
#include <vector>

namespace rap::protocol {

constexpr uint32_t MAGIC_HEADER = 0x52415030; // "RAP0"
constexpr uint16_t PROTOCOL_VERSION = 1;

enum class PayloadType : uint16_t {
    Unspecified = 0,
    HandshakeReq = 1,
    HandshakeResp = 2,
    FrameHeader = 3,
    InputEvent = 4,
    Heartbeat = 5,
    ClipboardData = 6,
    FileTransferRequest = 7,
    FileTransferResponse = 8,
    FileChunkPayload = 9,
    FileTransferControl = 10,
    DirectoryListRequest = 11,
    DirectoryListResponse = 12
};


enum class ParseError {
    None = 0,
    InvalidMagicHeader,
    UnsupportedVersion,
    IncompleteHeader,
    IncompletePayload,
    CorruptedPayload
};

struct PacketHeader {
    uint32_t magic{MAGIC_HEADER};
    uint16_t version{PROTOCOL_VERSION};
    PayloadType type{PayloadType::Unspecified};
    uint64_t sequenceNumber{0};
    uint64_t timestampMs{0};
    uint32_t payloadSize{0};
};

struct Packet {
    PacketHeader header;
    std::vector<uint8_t> payload;
};

using ParseResult = std::variant<Packet, ParseError>;

class ProtocolCodec {
public:
    static std::vector<uint8_t> encode(PayloadType type,
                                       uint64_t sequenceNumber,
                                       uint64_t timestampMs,
                                       const std::vector<uint8_t> &payload);

    static ParseResult decode(const uint8_t *data, size_t size);
};

} // namespace rap::protocol

#endif // RAP_PROTOCOL_CODEC_H
