#ifndef RAP_SECURITY_CRYPTO_ENGINE_H
#define RAP_SECURITY_CRYPTO_ENGINE_H

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

namespace rap::security {

constexpr size_t KEY_SIZE = 32;   // 256-bit symmetric / X25519 key size
constexpr size_t NONCE_SIZE = 12; // 96-bit ChaCha20-Poly1305 AEAD nonce
constexpr size_t TAG_SIZE = 16;   // 128-bit Poly1305 AEAD tag size

struct KeyPair {
    std::vector<uint8_t> publicKey;  // 32 bytes
    std::vector<uint8_t> privateKey; // 32 bytes
};

class CryptoEngine {
public:
    static KeyPair generateKeyPair();

    static std::vector<uint8_t> deriveSharedSecret(const std::vector<uint8_t>& ourPrivateKey,
                                                   const std::vector<uint8_t>& peerPublicKey);

    static std::vector<uint8_t> encryptPayload(const std::vector<uint8_t>& plaintext,
                                               const std::vector<uint8_t>& key,
                                               const std::vector<uint8_t>& nonce);

    static std::optional<std::vector<uint8_t>>
    decryptPayload(const std::vector<uint8_t>& ciphertext,
                   const std::vector<uint8_t>& key,
                   const std::vector<uint8_t>& nonce);

    static std::vector<uint8_t> generateRandomBytes(size_t count);
};

} // namespace rap::security

#endif // RAP_SECURITY_CRYPTO_ENGINE_H
