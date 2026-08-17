#include <QtTest>
#include "rap_mobile_c_api.h"
#include <cstring>

class TestMobileCApi : public QObject {

    Q_OBJECT

private slots:
    void initTestCase() {
        QCOMPARE(rap_mobile_init(), 0);
    }

    void testGetP2PId() {
        char buf[32] = {0};
        int32_t res = rap_mobile_get_p2p_id(buf, sizeof(buf));
        QCOMPARE(res, 0);
        QVERIFY(std::strlen(buf) > 0);
        QVERIFY(QString(buf).contains(" "));
    }

    void testEncodeDecodeRoundtrip() {
        uint8_t payload[] = {0x10, 0x20, 0x30, 0x40};
        uint8_t outBuf[256] = {0};
        size_t written = 0;

        int32_t encRes = rap_mobile_encode_packet(
            13, // AuthRequest
            42,
            1000,
            payload,
            sizeof(payload),
            outBuf,
            sizeof(outBuf),
            &written
        );
        QCOMPARE(encRes, 0);
        QVERIFY(written > 28);

        rap_c_packet_t pkt;
        std::memset(&pkt, 0, sizeof(pkt));
        int32_t decRes = rap_mobile_decode_packet(outBuf, written, &pkt);
        QCOMPARE(decRes, 0);
        QCOMPARE(pkt.payload_type, 13u);
        QCOMPARE(pkt.sequence_num, 42u);
        QCOMPARE(pkt.payload_size, sizeof(payload));
        QCOMPARE(std::memcmp(pkt.payload_data, payload, sizeof(payload)), 0);

        rap_mobile_free_packet(&pkt);
    }
};

QTEST_MAIN(TestMobileCApi)
#include "test_mobile_c_api.moc"
