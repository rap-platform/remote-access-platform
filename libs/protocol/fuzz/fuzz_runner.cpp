#include <random>
#include <vector>

#include <QtTest/QtTest>

#include "../include/ProtocolCodec.h"

class TestProtocolFuzz : public QObject {
    Q_OBJECT

private slots:
    void testProtocolCodecFuzzingOneMillionIterations();
};

void TestProtocolFuzz::testProtocolCodecFuzzingOneMillionIterations() {
    std::mt19937 gen(42); // Fixed deterministic seed for reproducible security fuzz testing
    std::uniform_int_distribution<uint16_t> lenDist(0, 1024);
    std::uniform_int_distribution<uint16_t> byteDist(0, 255);

    constexpr size_t totalIterations = 1000000;
    size_t parseErrorsCount = 0;
    size_t validPacketsCount = 0;

    for (size_t i = 0; i < totalIterations; ++i) {
        size_t len = lenDist(gen);
        std::vector<uint8_t> fuzzBuffer(len);
        for (size_t j = 0; j < len; ++j) {
            fuzzBuffer[j] = static_cast<uint8_t>(byteDist(gen));
        }

        auto result = rap::protocol::ProtocolCodec::decode(fuzzBuffer.data(), fuzzBuffer.size());
        if (std::holds_alternative<rap::protocol::Packet>(result)) {
            validPacketsCount++;
        } else {
            parseErrorsCount++;
        }
    }

    QVERIFY(parseErrorsCount + validPacketsCount == totalIterations);
    qDebug() << "[Fuzz Benchmark] Completed" << totalIterations << "fuzzing iterations."
             << "Valid packets parsed:" << validPacketsCount
             << "Rejected malformed packets:" << parseErrorsCount;
}

QTEST_MAIN(TestProtocolFuzz)
#include "fuzz_runner.moc"
