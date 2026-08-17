#include "../include/ProtocolCodec.h"
#include <cstddef>
#include <cstdint>

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
    // Fuzz test target for protocol binary parser
    auto res = rap::protocol::ProtocolCodec::decode(data, size);
    (void)res;
    return 0;
}
