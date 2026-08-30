#include "../include/WindowsDxgiCaptureBackend.h"

#include <chrono>
#include <iostream>

#ifdef _WIN32
#include <windows.h>
#include <d3d11.h>
#include <dxgi1_2.h>
#endif

namespace rap::capture {

WindowsDxgiCaptureBackend::WindowsDxgiCaptureBackend() = default;

WindowsDxgiCaptureBackend::~WindowsDxgiCaptureBackend() {
    stopCapture();
}

bool WindowsDxgiCaptureBackend::initialize() {
    std::lock_guard<std::mutex> lock(mutex_);
    initialized_ = true;
    return true;
}

std::vector<MonitorInfo> WindowsDxgiCaptureBackend::enumerateMonitors() {
    std::vector<MonitorInfo> monitors;
#ifdef _WIN32
    DISPLAY_DEVICEA dd;
    dd.cb = sizeof(dd);
    DWORD deviceNum = 0;

    while (EnumDisplayDevicesA(NULL, deviceNum, &dd, 0)) {
        if (dd.StateFlags & DISPLAY_DEVICE_ATTACHED_TO_DESKTOP) {
            DEVMODEA dm;
            dm.dmSize = sizeof(dm);
            if (EnumDisplaySettingsA(dd.DeviceName, ENUM_CURRENT_SETTINGS, &dm)) {
                MonitorInfo info;
                info.monitorId = deviceNum;
                info.name = std::string(dd.DeviceString);
                info.width = dm.dmPelsWidth;
                info.height = dm.dmPelsHeight;
                info.offsetX = dm.dmPosition.x;
                info.offsetY = dm.dmPosition.y;
                info.isPrimary = (dd.StateFlags & DISPLAY_DEVICE_PRIMARY_DEVICE) != 0;
                monitors.push_back(info);
            }
        }
        deviceNum++;
    }
#endif
    if (monitors.empty()) {
        MonitorInfo def;
        def.monitorId = 0;
        def.name = "Primary Display";
        def.width = 1920;
        def.height = 1080;
        def.isPrimary = true;
        monitors.push_back(def);
    }
    return monitors;
}

bool WindowsDxgiCaptureBackend::selectMonitor(uint32_t monitorId) {
    std::lock_guard<std::mutex> lock(mutex_);
    currentMonitorId_ = monitorId;
    return true;
}

bool WindowsDxgiCaptureBackend::startCapture(FrameCallback callback) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (isCapturing_) return true;

    frameCallback_ = callback;
    isCapturing_ = true;
    captureThread_ = std::thread(&WindowsDxgiCaptureBackend::captureLoop, this);
    return true;
}

void WindowsDxgiCaptureBackend::stopCapture() {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!isCapturing_) return;
        isCapturing_ = false;
    }
    if (captureThread_.joinable()) {
        captureThread_.join();
    }
}

bool WindowsDxgiCaptureBackend::isCapturing() const {
    return isCapturing_;
}

std::optional<FrameData> WindowsDxgiCaptureBackend::captureSingleFrame() {
    FrameData frame;
    frame.width = 1920;
    frame.height = 1080;
    frame.stride = 1920 * 4;
    frame.format = FrameFormat::RGBA8888;
    frame.frameNumber = ++frameCounter_;
    frame.timestampUs = std::chrono::duration_cast<std::chrono::microseconds>(
                            std::chrono::steady_clock::now().time_since_epoch()).count();
    frame.pixelData.resize(frame.stride * frame.height, 0x1E);
    return frame;
}

void WindowsDxgiCaptureBackend::captureLoop() {
    while (isCapturing_) {
        auto frameOpt = captureSingleFrame();
        if (frameOpt.has_value() && frameCallback_) {
            frameCallback_(*frameOpt);
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(33)); // ~30 FPS
    }
}

} // namespace rap::capture
