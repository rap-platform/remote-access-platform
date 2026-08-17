#ifndef RAP_CAPTURE_LINUX_X11_CAPTURE_H
#define RAP_CAPTURE_LINUX_X11_CAPTURE_H

#include "ICaptureBackend.h"
#include "AdaptiveBitrateController.h"
#include <atomic>
#include <thread>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

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

    uint32_t width() const { return width_; }
    uint32_t height() const { return height_; }
    AdaptiveBitrateController &bitrateController() { return bitrateController_; }

private:
    void stopCaptureInternal();

    uint32_t width_{1920};
    uint32_t height_{1080};
    uint64_t frameCounter_{0};
    std::atomic<bool> isCapturing_{false};
    std::atomic<bool> stopRequested_{false};
    std::thread captureThread_;

    Display *display_{nullptr};
    Window rootWindow_{0};
    std::vector<uint8_t> prevFrameData_;
    AdaptiveBitrateController bitrateController_{8000, 60};
};

} // namespace rap::capture

#endif // RAP_CAPTURE_LINUX_X11_CAPTURE_H
