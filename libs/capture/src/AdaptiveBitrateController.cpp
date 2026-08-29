#include "AdaptiveBitrateController.h"

#include <algorithm>

namespace rap::capture {

AdaptiveBitrateController::AdaptiveBitrateController(uint32_t initialBitrateKbps,
                                                     uint32_t initialFps) {
    m_settings.targetBitrateKbps = initialBitrateKbps;
    m_settings.targetFps = initialFps;
    m_settings.enableHardwareAcceleration = true;
}

CodecSettings AdaptiveBitrateController::updateTelemetry(uint32_t rttMs, float packetLossRate) {
    if (rttMs > 200 || packetLossRate > 0.05f) { // Severe congestion
        m_settings.targetFps = 15;
        m_settings.targetBitrateKbps = 2000;
    } else if (rttMs > 80 || packetLossRate > 0.01f) { // Moderate congestion
        m_settings.targetFps = 30;
        m_settings.targetBitrateKbps = 4500;
    } else { // High quality network
        m_settings.targetFps = 60;
        m_settings.targetBitrateKbps = 8000;
    }
    return m_settings;
}

} // namespace rap::capture

#ifndef __linux__
namespace rap::capture {

class CrossPlatformDummyCapture : public ICaptureBackend {
public:
    bool initialize() override { return true; }
    bool startCapture(FrameCallback) override { return true; }
    void stopCapture() override {}
    bool isCapturing() const override { return false; }
    std::optional<FrameData> captureSingleFrame() override { return std::nullopt; }
    std::string backendName() const override { return "CrossPlatform Stub Capture"; }
};

std::unique_ptr<ICaptureBackend> CaptureBackendFactory::createDefaultBackend() {
    return std::make_unique<CrossPlatformDummyCapture>();
}

} // namespace rap::capture
#endif
