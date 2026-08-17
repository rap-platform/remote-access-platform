#ifndef RAP_PROTOCOL_STUN_CLIENT_H
#define RAP_PROTOCOL_STUN_CLIENT_H

#include <cstdint>
#include <string>
#include <vector>

namespace rap::protocol {

constexpr uint32_t STUN_MAGIC_COOKIE_VAL = 0x2112A442;
constexpr uint16_t STUN_MSG_BINDING_REQUEST = 0x0001;

struct StunMappedAddress {
    std::string ip;
    uint16_t port{0};
    bool isBehindNat{false};
};

class StunClient {
public:
    static std::vector<uint8_t> createBindingRequest(const uint8_t transactionId[12]);
    static StunMappedAddress parseBindingResponse(const uint8_t *data, size_t size);
};

} // namespace rap::protocol

#endif // RAP_PROTOCOL_STUN_CLIENT_H
