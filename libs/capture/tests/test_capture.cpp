#include <QSignalSpy>
#include <QTest>

#include "../include/ICaptureBackend.h"
#include "../include/LinuxDrmCapture.h"

class TestCapture : public QObject {
    Q_OBJECT

private slots:
    void testBackendInitialization() {
        auto backend = rap::capture::CaptureBackendFactory::createDefaultBackend();
        QVERIFY(backend != nullptr);
        QVERIFY(backend->initialize());
        QCOMPARE(backend->backendName(), std::string("Linux X11 Capture Backend"));
    }

    void testSingleFrameCapture() {
        auto backend = rap::capture::CaptureBackendFactory::createDefaultBackend();
        QVERIFY(backend->initialize());

        auto frameOpt = backend->captureSingleFrame();
        QVERIFY(frameOpt.has_value());

        const auto& frame = frameOpt.value();
        QCOMPARE(frame.width, static_cast<uint32_t>(1920));
        QCOMPARE(frame.height, static_cast<uint32_t>(1080));
        QCOMPARE(frame.format, rap::capture::FrameFormat::RGBA8888);
        QVERIFY(!frame.pixelData.empty());
    }

    void testStartStopCaptureThread() {
        auto backend = rap::capture::CaptureBackendFactory::createDefaultBackend();
        QVERIFY(backend->initialize());

        std::atomic<int> frameCount{0};
        bool started = backend->startCapture([&frameCount](const rap::capture::FrameData& frame) {
            (void)frame;
            frameCount++;
        });

        QVERIFY(started);
        QVERIFY(backend->isCapturing());

        QTest::qWait(200);

        backend->stopCapture();
        QVERIFY(!backend->isCapturing());
        QVERIFY(frameCount.load() > 0);
    }

    void testLinuxDrmBackend() {
        rap::capture::LinuxDrmCapture drmBackend;
        QVERIFY(drmBackend.initialize());
        QCOMPARE(drmBackend.backendName(), std::string("LinuxDRM/KMS Framebuffer"));

        auto frameOpt = drmBackend.captureSingleFrame();
        QVERIFY(frameOpt.has_value());
        QCOMPARE(frameOpt->width, static_cast<uint32_t>(1920));
        QCOMPARE(frameOpt->height, static_cast<uint32_t>(1080));
        QVERIFY(!frameOpt->pixelData.empty());
    }
};

QTEST_MAIN(TestCapture)
#include "test_capture.moc"
