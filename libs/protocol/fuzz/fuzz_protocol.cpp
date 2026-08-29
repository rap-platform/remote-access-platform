#include <cstddef>
#include <cstdint>

#include "../include/ProtocolCodec.h"

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
    if (data == nullptr || size == 0) {
        return 0;
    }

    // Fuzz test target for binary protocol decoder
    auto res = rap::protocol::ProtocolCodec::decode(data, size);
    (void)res;

    // Fuzz test target for binary protocol encoder
    if (size >= 16) {
        uint64_t seq = *reinterpret_cast<const uint64_t*>(data);
        uint64_t ts = *reinterpret_cast<const uint64_t*>(data + 8);
        std::vector<uint8_t> payload(data + 16, data + size);
        auto encoded = rap::protocol::ProtocolCodec::encode(rap::protocol::PayloadType::FrameHeader,
                                                            seq,
                                                            ts,
                                                            payload);
        (void)encoded;
    }

    return 0;
}
