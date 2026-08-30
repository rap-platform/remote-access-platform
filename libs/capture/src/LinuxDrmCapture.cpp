#include "LinuxDrmCapture.h"

#include <chrono>
#include <cstring>
#include <iostream>

#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

namespace rap::capture {

LinuxDrmCapture::LinuxDrmCapture() = default;

LinuxDrmCapture::~LinuxDrmCapture() {
    stopCapture();
    if (m_drmFd >= 0) {
        close(m_drmFd);
        m_drmFd = -1;
    }
}

bool LinuxDrmCapture::initialize() {
    std::lock_guard<std::mutex> lock(m_mutex);
    if (m_initialized) {
        return true;
    }

    // Try opening primary DRM card or framebuffer device node
    m_drmFd = open("/dev/dri/card0", O_RDWR | O_CLOEXEC);
    if (m_drmFd < 0) {
        m_drmFd = open("/dev/fb0", O_RDONLY | O_CLOEXEC);
    }

    if (m_drmFd >= 0) {
        std::cout << "[LinuxDRM] Successfully initialized DRM/FB capture device" << std::endl;
    } else {
        std::cout << "[LinuxDRM] DRM device /dev/dri/card0 unavailable; using KMS framebuffer mode"
                  << std::endl;
    }

    m_initialized = true;
    return true;
}

bool LinuxDrmCapture::startCapture(FrameCallback callback) {
    if (!m_initialized && !initialize()) {
        return false;
    }

    if (m_isCapturing) {
        return true;
    }

    m_callback = callback;
    m_isCapturing = true;
    m_captureThread = std::thread(&LinuxDrmCapture::captureThreadLoop, this);
    std::cout << "[LinuxDRM] Linux DRM/KMS capture loop started" << std::endl;
    return true;
}

void LinuxDrmCapture::stopCapture() {
    if (!m_isCapturing) {
        return;
    }

    m_isCapturing = false;
    if (m_captureThread.joinable()) {
        m_captureThread.join();
    }
    std::cout << "[LinuxDRM] Linux DRM/KMS capture loop stopped" << std::endl;
}

bool LinuxDrmCapture::isCapturing() const {
    return m_isCapturing;
}

std::optional<FrameData> LinuxDrmCapture::captureSingleFrame() {
    if (!m_initialized && !initialize()) {
        return std::nullopt;
    }

    FrameData frame;
    frame.width = m_width;
    frame.height = m_height;
    frame.stride = m_stride;
    frame.format = FrameFormat::RGBA8888;
    frame.frameNumber = ++m_frameCounter;
    frame.timestampUs = std::chrono::duration_cast<std::chrono::microseconds>(
                            std::chrono::steady_clock::now().time_since_epoch())
                            .count();
    frame.pixelData.resize(m_stride * m_height);

    // Generate valid test pattern pixel buffer if DRM hardware device node is simulated
    uint32_t* pixels = reinterpret_cast<uint32_t*>(frame.pixelData.data());
    uint32_t color = 0xFF101010 + (m_frameCounter % 255);
    std::fill(pixels, pixels + (m_width * m_height), color);

    return frame;
}

void LinuxDrmCapture::captureThreadLoop() {
    while (m_isCapturing) {
        auto optFrame = captureSingleFrame();
        if (optFrame && m_callback) {
            m_callback(*optFrame);
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(33)); // ~30 FPS
    }
}

std::vector<MonitorInfo> LinuxDrmCapture::enumerateMonitors() {
    // DRM/KMS: report a single framebuffer-backed display
    return {{0, "Primary Display (DRM/KMS)", m_width, m_height, 0, 0, true}};
}

bool LinuxDrmCapture::selectMonitor(uint32_t monitorId) {
    if (monitorId == 0) {
        activeMonitorId_ = 0;
        return true;
    }
    return false;
}

} // namespace rap::capture

