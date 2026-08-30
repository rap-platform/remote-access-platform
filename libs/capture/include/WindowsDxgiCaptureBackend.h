#ifndef RAP_CAPTURE_WINDOWS_DXGI_CAPTURE_BACKEND_H
#define RAP_CAPTURE_WINDOWS_DXGI_CAPTURE_BACKEND_H

#include <atomic>
#include <mutex>
#include <thread>
#include <vector>

#include "ICaptureBackend.h"

namespace rap::capture {

class WindowsDxgiCaptureBackend : public ICaptureBackend {
public:
    WindowsDxgiCaptureBackend();
    ~WindowsDxgiCaptureBackend() override;

    bool initialize() override;
    bool startCapture(FrameCallback callback) override;
    void stopCapture() override;
    bool isCapturing() const override;
    std::optional<FrameData> captureSingleFrame() override;
    std::string backendName() const override { return "Windows DXGI Desktop Duplication"; }

    std::vector<MonitorInfo> enumerateMonitors() override;
    bool selectMonitor(uint32_t monitorId) override;
    uint32_t currentMonitorId() const override { return currentMonitorId_; }

private:
    std::atomic<bool> isCapturing_{false};
    std::atomic<bool> initialized_{false};
    uint32_t currentMonitorId_{0};
    uint64_t frameCounter_{0};

    FrameCallback frameCallback_;
    std::thread captureThread_;
    mutable std::mutex mutex_;

    void captureLoop();
};

} // namespace rap::capture

#endif // RAP_CAPTURE_WINDOWS_DXGI_CAPTURE_BACKEND_H
