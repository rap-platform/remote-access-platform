#ifndef RAP_CAPTURE_LINUX_X11_CAPTURE_H
#define RAP_CAPTURE_LINUX_X11_CAPTURE_H

#include "../include/ICaptureBackend.h"
#include <atomic>
#include <thread>

namespace rap::capture {

class LinuxX11Capture : public ICaptureBackend {
public:
    LinuxX11Capture() = default;
    ~LinuxX11Capture() override;

    bool initialize() override;
    bool startCapture(FrameCallback callback) override;
    void stopCapture() override;
    bool isCapturing() const override { return isCapturing_.load(); }
    std::optional<FrameData> captureSingleFrame() override;
    std::string backendName() const override { return "Linux X11 Capture Backend"; }

private:
    void stopCaptureInternal();

    std::atomic<bool> isCapturing_{false};
    std::atomic<bool> stopRequested_{false};
    std::thread captureThread_;
    uint64_t frameCounter_{0};
    uint32_t width_{1920};
    uint32_t height_{1080};
};

} // namespace rap::capture

#endif // RAP_CAPTURE_LINUX_X11_CAPTURE_H
