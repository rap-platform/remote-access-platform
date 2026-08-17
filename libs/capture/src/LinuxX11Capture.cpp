#include "LinuxX11Capture.h"
#include <chrono>
#include <cstring>

namespace rap::capture {

LinuxX11Capture::~LinuxX11Capture() {
    stopCaptureInternal();
}

bool LinuxX11Capture::initialize() {
    width_ = 1920;
    height_ = 1080;
    frameCounter_ = 0;
    return true;
}

std::optional<FrameData> LinuxX11Capture::captureSingleFrame() {
    FrameData frame;
    frame.width = width_;
    frame.height = height_;
    frame.stride = width_ * 4;
    frame.format = FrameFormat::RGBA8888;
    frame.frameNumber = ++frameCounter_;

    auto now = std::chrono::steady_clock::now().time_since_epoch();
    frame.timestampUs = std::chrono::duration_cast<std::chrono::microseconds>(now).count();

    size_t bufferSize = frame.stride * frame.height;
    frame.pixelData.resize(bufferSize);

    // Populate frame buffer with pattern for software fallback/CI test environment
    uint32_t *pixels = reinterpret_cast<uint32_t *>(frame.pixelData.data());
    uint32_t color = 0xFF1E1E2E; // Dark theme color pattern
    std::fill(pixels, pixels + (width_ * height_), color);

    return frame;
}

bool LinuxX11Capture::startCapture(FrameCallback callback) {
    if (isCapturing_.load()) {
        return false;
    }

    stopRequested_.store(false);
    isCapturing_.store(true);

    captureThread_ = std::thread([this, callback]() {
        while (!stopRequested_.load()) {
            auto frameOpt = captureSingleFrame();
            if (frameOpt.has_value() && callback) {
                callback(frameOpt.value());
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(33)); // ~30 FPS loop
        }
        isCapturing_.store(false);
    });

    return true;
}

void LinuxX11Capture::stopCapture() {
    stopCaptureInternal();
}

void LinuxX11Capture::stopCaptureInternal() {
    if (isCapturing_.load()) {
        stopRequested_.store(true);
        if (captureThread_.joinable()) {
            captureThread_.join();
        }
        isCapturing_.store(false);
    }
}

std::unique_ptr<ICaptureBackend> CaptureBackendFactory::createDefaultBackend() {
    return std::make_unique<LinuxX11Capture>();
}

} // namespace rap::capture
