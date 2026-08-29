#include <QtTest/QtTest>

#include "CryptoEngine.h"

using namespace rap::security;

class TestCryptoEngine : public QObject {
    Q_OBJECT

private slots:
    void testKeyPairGeneration();
    void testECDHKeyDerivation();
    void testEncryptDecryptRoundtrip();
    void testTamperDetection();
};

void TestCryptoEngine::testKeyPairGeneration() {
    KeyPair kp1 = CryptoEngine::generateKeyPair();
    KeyPair kp2 = CryptoEngine::generateKeyPair();

    QCOMPARE(kp1.privateKey.size(), KEY_SIZE);
    QCOMPARE(kp1.publicKey.size(), KEY_SIZE);
    QVERIFY(kp1.privateKey != kp2.privateKey);
}

void TestCryptoEngine::testECDHKeyDerivation() {
    KeyPair alice = CryptoEngine::generateKeyPair();
    KeyPair bob = CryptoEngine::generateKeyPair();

    auto secretAlice = CryptoEngine::deriveSharedSecret(alice.privateKey, bob.publicKey);
    auto secretBob = CryptoEngine::deriveSharedSecret(bob.privateKey, alice.publicKey);

    QCOMPARE(secretAlice.size(), KEY_SIZE);
    QCOMPARE(secretAlice, secretBob);
}

void TestCryptoEngine::testEncryptDecryptRoundtrip() {
    auto key = CryptoEngine::generateRandomBytes(KEY_SIZE);
    auto nonce = CryptoEngine::generateRandomBytes(NONCE_SIZE);

    std::string message = "Remote Access Platform — End-to-End Encrypted Video Payload";
    std::vector<uint8_t> plaintext(message.begin(), message.end());

    auto ciphertext = CryptoEngine::encryptPayload(plaintext, key, nonce);
    QCOMPARE(ciphertext.size(), plaintext.size() + TAG_SIZE);

    auto decrypted = CryptoEngine::decryptPayload(ciphertext, key, nonce);
    QVERIFY(decrypted.has_value());
    QCOMPARE(decrypted.value(), plaintext);
}

void TestCryptoEngine::testTamperDetection() {
    auto key = CryptoEngine::generateRandomBytes(KEY_SIZE);
    auto nonce = CryptoEngine::generateRandomBytes(NONCE_SIZE);

    std::vector<uint8_t> plaintext = {0x01, 0x02, 0x03, 0x04, 0x05};
    auto ciphertext = CryptoEngine::encryptPayload(plaintext, key, nonce);

    // Tamper with one byte in the ciphertext
    ciphertext[0] ^= 0xFF;

    auto decrypted = CryptoEngine::decryptPayload(ciphertext, key, nonce);
    QVERIFY(!decrypted.has_value());
}

QTEST_MAIN(TestCryptoEngine)
#include "test_crypto.moc"
