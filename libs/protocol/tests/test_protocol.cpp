#include <QTest>

#include "../include/ProtocolCodec.h"

class TestProtocol : public QObject {
    Q_OBJECT

private slots:
    void testEncodeDecodeRoundtrip() {
        std::vector<uint8_t> payload = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08};
        uint64_t seq = 1001;
        uint64_t ts = 1723890000000;

        auto encoded = rap::protocol::ProtocolCodec::encode(rap::protocol::PayloadType::InputEvent,
                                                            seq,
                                                            ts,
                                                            payload);

        QCOMPARE(encoded.size(), static_cast<size_t>(28 + 8));

        auto decodedRes = rap::protocol::ProtocolCodec::decode(encoded.data(), encoded.size());
        QVERIFY(std::holds_alternative<rap::protocol::Packet>(decodedRes));

        const auto& packet = std::get<rap::protocol::Packet>(decodedRes);
        QCOMPARE(packet.header.magic, rap::protocol::MAGIC_HEADER);
        QCOMPARE(packet.header.version, rap::protocol::PROTOCOL_VERSION);
        QCOMPARE(static_cast<uint16_t>(packet.header.type),
                 static_cast<uint16_t>(rap::protocol::PayloadType::InputEvent));
        QCOMPARE(packet.header.sequenceNumber, seq);
        QCOMPARE(packet.header.timestampMs, ts);
        QCOMPARE(packet.header.payloadSize, static_cast<uint32_t>(8));
        QCOMPARE(packet.payload, payload);
    }

    void testIncompleteHeader() {
        std::vector<uint8_t> shortData = {0x52, 0x41, 0x50};
        auto res = rap::protocol::ProtocolCodec::decode(shortData.data(), shortData.size());
        QVERIFY(std::holds_alternative<rap::protocol::ParseError>(res));
        QCOMPARE(std::get<rap::protocol::ParseError>(res),
                 rap::protocol::ParseError::IncompleteHeader);
    }

    void testInvalidMagicHeader() {
        std::vector<uint8_t> invalidMagic = {
            0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
        auto res = rap::protocol::ProtocolCodec::decode(invalidMagic.data(), invalidMagic.size());
        QVERIFY(std::holds_alternative<rap::protocol::ParseError>(res));
        QCOMPARE(std::get<rap::protocol::ParseError>(res),
                 rap::protocol::ParseError::InvalidMagicHeader);
    }
};

QTEST_MAIN(TestProtocol)
#include "test_protocol.moc"
