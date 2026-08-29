// Cross-platform stub capture backend for Windows and macOS.
// On Linux, the real X11/DRM backends in LinuxX11Capture.cpp are used instead.
#ifndef __linux__

#include <memory>
#include <optional>
#include <string>

#include "ICaptureBackend.h"

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

#endif // !__linux__
