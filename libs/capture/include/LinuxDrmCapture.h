#ifndef RAP_CAPTURE_LINUX_DRM_CAPTURE_H
#define RAP_CAPTURE_LINUX_DRM_CAPTURE_H

#include <atomic>
#include <mutex>
#include <thread>

#include "ICaptureBackend.h"

namespace rap::capture {

/**
 * Direct Linux DRM/KMS Framebuffer Screen Capture Backend
 * Provides headless desktop screen capture for embedded Linux & Yocto environments
 * without requiring X11 or Wayland display servers.
 */
class LinuxDrmCapture : public ICaptureBackend {
public:
    LinuxDrmCapture();
    ~LinuxDrmCapture() override;

    bool initialize() override;
    bool startCapture(FrameCallback callback) override;
    void stopCapture() override;
    bool isCapturing() const override;
    std::optional<FrameData> captureSingleFrame() override;
    std::string backendName() const override { return "LinuxDRM/KMS Framebuffer"; }

    std::vector<MonitorInfo> enumerateMonitors() override;
    bool selectMonitor(uint32_t monitorId) override;
    uint32_t currentMonitorId() const override { return activeMonitorId_; }

private:
    void captureThreadLoop();

    std::atomic<bool> m_isCapturing{false};
    std::atomic<bool> m_initialized{false};
    std::thread m_captureThread;
    FrameCallback m_callback;

    uint32_t m_width{1920};
    uint32_t m_height{1080};
    uint32_t m_stride{1920 * 4};
    uint64_t m_frameCounter{0};
    int m_drmFd{-1};
    mutable std::mutex m_mutex;
    uint32_t activeMonitorId_{0};
};

} // namespace rap::capture

#endif // RAP_CAPTURE_LINUX_DRM_CAPTURE_H
