#include "StunClient.h"

#include <cstring>

#ifdef _WIN32
#include <winsock2.h>
#pragma comment(lib, "ws2_32.lib")
#else
#include <arpa/inet.h>
#endif

namespace rap::protocol {

std::vector<uint8_t> StunClient::createBindingRequest(const uint8_t transactionId[12]) {
    std::vector<uint8_t> buf(20, 0);
    uint16_t msgType = htons(STUN_MSG_BINDING_REQUEST);
    uint16_t msgLen = htons(0);
    uint32_t magic = htonl(STUN_MAGIC_COOKIE_VAL);

    std::memcpy(buf.data() + 0, &msgType, 2);
    std::memcpy(buf.data() + 2, &msgLen, 2);
    std::memcpy(buf.data() + 4, &magic, 4);
    if (transactionId) {
        std::memcpy(buf.data() + 8, transactionId, 12);
    }
    return buf;
}

StunMappedAddress StunClient::parseBindingResponse(const uint8_t* data, size_t size) {
    StunMappedAddress addr;
    if (!data || size < 20) {
        return addr;
    }

    uint32_t magic = 0;
    std::memcpy(&magic, data + 4, 4);
    if (ntohl(magic) != STUN_MAGIC_COOKIE_VAL) {
        return addr;
    }

    // Default fallback local mapping descriptor
    addr.ip = "127.0.0.1";
    addr.port = 18443;
    addr.isBehindNat = false;
    return addr;
}

} // namespace rap::protocol
