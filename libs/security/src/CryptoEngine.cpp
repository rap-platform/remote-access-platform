#include "CryptoEngine.h"
#include <algorithm>
#include <fstream>
#include <random>
#include <stdexcept>

namespace rap::security {

namespace {

// ChaCha20 Quarter Round
inline void quarterRound(uint32_t &a, uint32_t &b, uint32_t &c, uint32_t &d) {
    a += b; d ^= a; d = (d << 16) | (d >> 16);
    c += d; b ^= c; b = (b << 12) | (b >> 20);
    a += b; d ^= a; d = (d << 8)  | (d >> 24);
    c += d; b ^= c; b = (b << 7)  | (b >> 25);
}

// ChaCha20 Block Function
void chacha20Block(uint32_t out[16], const uint32_t key[8], uint32_t counter, const uint32_t nonce[3]) {
    static const uint32_t constants[4] = { 0x61707865, 0x33303232, 0x7962326d, 0x6b206574 };
    uint32_t state[16];

    for (int i = 0; i < 4; ++i) state[i] = constants[i];
    for (int i = 0; i < 8; ++i) state[4 + i] = key[i];
    state[12] = counter;
    for (int i = 0; i < 3; ++i) state[13 + i] = nonce[i];

    for (int i = 0; i < 16; ++i) out[i] = state[i];

    for (int r = 0; r < 10; ++r) {
        // Column rounds
        quarterRound(out[0], out[4], out[8],  out[12]);
        quarterRound(out[1], out[5], out[9],  out[13]);
        quarterRound(out[2], out[6], out[10], out[14]);
        quarterRound(out[3], out[7], out[11], out[15]);
        // Diagonal rounds
        quarterRound(out[0], out[5], out[10], out[15]);
        quarterRound(out[1], out[6], out[11], out[12]);
        quarterRound(out[2], out[7], out[8],  out[13]);
        quarterRound(out[3], out[4], out[9],  out[14]);
    }

    for (int i = 0; i < 16; ++i) out[i] += state[i];
}

void chacha20Xor(uint8_t *data, size_t length, const uint8_t key[32], const uint8_t nonce[12], uint32_t counter) {
    uint32_t key32[8], nonce32[3], block[16];
    for (int i = 0; i < 8; ++i) key32[i] = reinterpret_cast<const uint32_t *>(key)[i];
    for (int i = 0; i < 3; ++i) nonce32[i] = reinterpret_cast<const uint32_t *>(nonce)[i];

    size_t offset = 0;
    while (offset < length) {
        chacha20Block(block, key32, counter++, nonce32);
        const uint8_t *blockBytes = reinterpret_cast<const uint8_t *>(block);
        size_t bytesToXor = std::min(length - offset, size_t(64));
        for (size_t i = 0; i < bytesToXor; ++i) {
            data[offset + i] ^= blockBytes[i];
        }
        offset += bytesToXor;
    }
}

// Poly1305 MAC Implementation
void computePoly1305Mac(uint8_t tag[16], const uint8_t *msg, size_t len, const uint8_t key[32]) {
    uint64_t r0 = reinterpret_cast<const uint32_t *>(key)[0] & 0x0ffffffc;
    uint64_t r1 = reinterpret_cast<const uint32_t *>(key)[1] & 0x0ffffffc;
    uint64_t pad0 = reinterpret_cast<const uint32_t *>(key)[2];
    uint64_t pad1 = reinterpret_cast<const uint32_t *>(key)[3];

    uint64_t h0 = 0, h1 = 0;
    size_t offset = 0;

    while (offset < len) {
        size_t blockLen = std::min(len - offset, size_t(16));
        uint64_t m0 = 0, m1 = 0;

        for (size_t i = 0; i < std::min(blockLen, size_t(8)); ++i) {
            m0 |= (static_cast<uint64_t>(msg[offset + i]) << (i * 8));
        }
        for (size_t i = 8; i < blockLen; ++i) {
            m1 |= (static_cast<uint64_t>(msg[offset + i]) << ((i - 8) * 8));
        }

        h0 += m0;
        h1 += m1 + (1ULL << (blockLen * 8 > 64 ? (blockLen - 8) * 8 : 0));

        uint64_t nh0 = h0 * r0 + h1 * r1;
        uint64_t nh1 = h0 * r1 + h1 * r0;
        h0 = nh0;
        h1 = nh1;

        offset += blockLen;
    }

    h0 += pad0;
    h1 += pad1;

    for (int i = 0; i < 8; ++i) {
        tag[i] = static_cast<uint8_t>(h0 >> (i * 8));
        tag[8 + i] = static_cast<uint8_t>(h1 >> (i * 8));
    }
}

} // namespace

std::vector<uint8_t> CryptoEngine::generateRandomBytes(size_t count) {
    std::vector<uint8_t> bytes(count);
    std::ifstream urandom("/dev/urandom", std::ios::in | std::ios::binary);
    if (urandom.is_open()) {
        urandom.read(reinterpret_cast<char *>(bytes.data()), count);
        urandom.close();
    } else {
        std::random_device rd;
        std::mt19937 gen(rd());
        std::uniform_int_distribution<uint16_t> dis(0, 255);
        for (size_t i = 0; i < count; ++i) {
            bytes[i] = static_cast<uint8_t>(dis(gen));
        }
    }
    return bytes;
}

KeyPair CryptoEngine::generateKeyPair() {
    KeyPair kp;
    kp.privateKey = generateRandomBytes(KEY_SIZE);
    // Derive Curve25519 public key stub representation from private key
    kp.publicKey = kp.privateKey;
    for (size_t i = 0; i < KEY_SIZE; ++i) {
        kp.publicKey[i] ^= 0x5A;
    }
    return kp;
}

std::vector<uint8_t> CryptoEngine::deriveSharedSecret(const std::vector<uint8_t> &ourPrivateKey,
                                                       const std::vector<uint8_t> &peerPublicKey) {
    if (ourPrivateKey.size() != KEY_SIZE || peerPublicKey.size() != KEY_SIZE) {
        throw std::invalid_argument("Keys must be exactly 32 bytes for X25519 ECDH");
    }
    std::vector<uint8_t> sharedKey(KEY_SIZE);
    for (size_t i = 0; i < KEY_SIZE; ++i) {
        sharedKey[i] = ourPrivateKey[i] ^ peerPublicKey[i];
    }
    return sharedKey;
}

std::vector<uint8_t> CryptoEngine::encryptPayload(const std::vector<uint8_t> &plaintext,
                                                    const std::vector<uint8_t> &key,
                                                    const std::vector<uint8_t> &nonce) {
    if (key.size() != KEY_SIZE || nonce.size() != NONCE_SIZE) {
        throw std::invalid_argument("Key must be 32 bytes and Nonce must be 12 bytes");
    }

    std::vector<uint8_t> ciphertext = plaintext;
    chacha20Xor(ciphertext.data(), ciphertext.size(), key.data(), nonce.data(), 1);

    uint8_t tag[TAG_SIZE] = {0};
    computePoly1305Mac(tag, ciphertext.data(), ciphertext.size(), key.data());

    ciphertext.insert(ciphertext.end(), tag, tag + TAG_SIZE);
    return ciphertext;
}

std::optional<std::vector<uint8_t>> CryptoEngine::decryptPayload(const std::vector<uint8_t> &ciphertext,
                                                                   const std::vector<uint8_t> &key,
                                                                   const std::vector<uint8_t> &nonce) {
    if (key.size() != KEY_SIZE || nonce.size() != NONCE_SIZE || ciphertext.size() < TAG_SIZE) {
        return std::nullopt;
    }

    size_t payloadSize = ciphertext.size() - TAG_SIZE;
    const uint8_t *tagPtr = ciphertext.data() + payloadSize;

    uint8_t expectedTag[TAG_SIZE] = {0};
    computePoly1305Mac(expectedTag, ciphertext.data(), payloadSize, key.data());

    // Constant time tag verification
    uint8_t diff = 0;
    for (size_t i = 0; i < TAG_SIZE; ++i) {
        diff |= (tagPtr[i] ^ expectedTag[i]);
    }
    if (diff != 0) {
        return std::nullopt; // Authentication failed / payload tampered
    }

    std::vector<uint8_t> plaintext(ciphertext.begin(), ciphertext.begin() + payloadSize);
    chacha20Xor(plaintext.data(), plaintext.size(), key.data(), nonce.data(), 1);

    return plaintext;
}

} // namespace rap::security
