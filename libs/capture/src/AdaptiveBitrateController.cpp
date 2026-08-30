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
