#ifndef RAP_CAPTURE_ADAPTIVE_BITRATE_CONTROLLER_H
#define RAP_CAPTURE_ADAPTIVE_BITRATE_CONTROLLER_H

#include <cstdint>

namespace rap::capture {

struct CodecSettings {
    uint32_t targetBitrateKbps{8000};
    uint32_t targetFps{60};
    bool enableHardwareAcceleration{true};
};

class AdaptiveBitrateController {
public:
    AdaptiveBitrateController(uint32_t initialBitrateKbps = 8000, uint32_t initialFps = 60);

    CodecSettings updateTelemetry(uint32_t rttMs, float packetLossRate);
    CodecSettings getSettings() const { return m_settings; }

private:
    CodecSettings m_settings;
};

} // namespace rap::capture

#endif // RAP_CAPTURE_ADAPTIVE_BITRATE_CONTROLLER_H
