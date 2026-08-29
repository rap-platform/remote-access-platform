#include <QtTest/QtTest>

#include "AdaptiveBitrateController.h"
#include "DirtyRegionDetector.h"
#include "MirrorShield.h"

using namespace rap::capture;

class TestPerformance : public QObject {
    Q_OBJECT

private slots:
    void testDirtyRegionDetection();
    void testMirrorShieldOverlay();
    void testAdaptiveBitrateScaling();
};

void TestPerformance::testDirtyRegionDetection() {
    constexpr int width = 100;
    constexpr int height = 100;
    constexpr int bpp = 4;
    std::vector<uint8_t> frame1(width * height * bpp, 0);
    std::vector<uint8_t> frame2 = frame1;

    // Modify a 20x20 region at (10, 10)
    for (int y = 10; y < 30; ++y) {
        for (int x = 10; x < 30; ++x) {
            frame2[(y * width + x) * bpp] = 0xff;
        }
    }

    DirtyRect rect =
        DirtyRegionDetector::detectDirtyRegion(frame1.data(), frame2.data(), width, height, bpp);
    QVERIFY(rect.isDirty);
    QVERIFY(rect.x <= 10);
    QVERIFY(rect.y <= 10);
    QVERIFY(rect.width >= 20);
    QVERIFY(rect.height >= 20);
}

void TestPerformance::testMirrorShieldOverlay() {
    constexpr int width = 200;
    constexpr int height = 200;
    constexpr int bpp = 4;
    std::vector<uint8_t> frame(width * height * bpp, 0xff);

    WindowBounds clientBounds;
    clientBounds.x = 50;
    clientBounds.y = 50;
    clientBounds.width = 100;
    clientBounds.height = 100;
    clientBounds.isActive = true;

    bool applied = MirrorShield::applyMirrorShield(frame.data(), width, height, clientBounds, bpp);
    QVERIFY(applied);

    // Verify dark privacy pattern inside shield bounds
    int offset = (60 * width + 60) * bpp;
    QCOMPARE(frame[offset + 0], static_cast<uint8_t>(0x1e));
    QCOMPARE(frame[offset + 1], static_cast<uint8_t>(0x1e));
    QCOMPARE(frame[offset + 2], static_cast<uint8_t>(0x2e));
}

void TestPerformance::testAdaptiveBitrateScaling() {
    AdaptiveBitrateController controller(8000, 60);

    // Good network
    CodecSettings s1 = controller.updateTelemetry(20, 0.001f);
    QCOMPARE(s1.targetFps, 60u);
    QCOMPARE(s1.targetBitrateKbps, 8000u);

    // High congestion network
    CodecSettings s2 = controller.updateTelemetry(250, 0.08f);
    QCOMPARE(s2.targetFps, 15u);
    QCOMPARE(s2.targetBitrateKbps, 2000u);
}

QTEST_MAIN(TestPerformance)
#include "test_performance.moc"
