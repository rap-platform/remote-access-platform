#include "LinuxX11Capture.h"

#include <chrono>
#include <cstdlib>
#include <cstring>
#include <iostream>

#include "DirtyRegionDetector.h"
#include "LinuxDrmCapture.h"
#include "MirrorShield.h"

namespace rap::capture {

LinuxX11Capture::~LinuxX11Capture() {
    stopCaptureInternal();
    if (display_) {
        XCloseDisplay(display_);
        display_ = nullptr;
    }
}

bool LinuxX11Capture::initialize() {
    display_ = XOpenDisplay(nullptr);
    if (display_) {
        int screen = DefaultScreen(display_);
        rootWindow_ = RootWindow(display_, screen);
        width_ = static_cast<uint32_t>(DisplayWidth(display_, screen));
        height_ = static_cast<uint32_t>(DisplayHeight(display_, screen));
    } else {
        width_ = 1920;
        height_ = 1080;
    }
    frameCounter_ = 0;
    prevFrameData_.clear();
    return true;
}

// Fetch window title reliably across standard X11 and Extended Window Manager Hints (_NET_WM_NAME)
[[maybe_unused]] static std::string getWindowTitle(Display* display, Window window) {
    if (!display || !window)
        return "";
    char* name = nullptr;
    if (XFetchName(display, window, &name) && name) {
        std::string title(name);
        XFree(name);
        return title;
    }
    Atom netWmName = XInternAtom(display, "_NET_WM_NAME", True);
    if (netWmName != None) {
        Atom actualType;
        int actualFormat;
        unsigned long nItems, bytesAfter;
        unsigned char* prop = nullptr;
        if (XGetWindowProperty(display,
                               window,
                               netWmName,
                               0,
                               1024,
                               False,
                               AnyPropertyType,
                               &actualType,
                               &actualFormat,
                               &nItems,
                               &bytesAfter,
                               &prop) == Success &&
            prop) {
            std::string title(reinterpret_cast<char*>(prop));
            XFree(prop);
            return title;
        }
    }
    return "";
}

// Recursive window tree search finding client viewer window and translating local coordinates to
// root desktop screen space
[[maybe_unused]] static bool searchClientWindow(Display* display,
                                                Window rootWindow,
                                                Window currentWindow,
                                                WindowBounds& outBounds) {
    std::string title = getWindowTitle(display, currentWindow);
    if (!title.empty() && title.find("Remote Access Platform") != std::string::npos) {
        XWindowAttributes attr;
        if (XGetWindowAttributes(display, currentWindow, &attr) && attr.width > 100 &&
            attr.height > 100) {
            int rootX = 0, rootY = 0;
            Window childReturn;
            XTranslateCoordinates(display,
                                  currentWindow,
                                  rootWindow,
                                  0,
                                  0,
                                  &rootX,
                                  &rootY,
                                  &childReturn);
            outBounds.x = rootX;
            outBounds.y = rootY;
            outBounds.width = attr.width;
            outBounds.height = attr.height;
            outBounds.isActive = true;
            return true;
        }
    }

    Window rootReturn, parentReturn, *children = nullptr;
    unsigned int numChildren = 0;
    if (XQueryTree(display, currentWindow, &rootReturn, &parentReturn, &children, &numChildren) &&
        children) {
        for (unsigned int i = 0; i < numChildren; ++i) {
            if (searchClientWindow(display, rootWindow, children[i], outBounds)) {
                XFree(children);
                return true;
            }
        }
        XFree(children);
    }
    return false;
}

[[maybe_unused]] static WindowBounds findClientWindowBounds(Display* display, Window rootWindow) {
    WindowBounds bounds;
    if (!display || !rootWindow)
        return bounds;
    searchClientWindow(display, rootWindow, rootWindow, bounds);
    return bounds;
}

std::optional<FrameData> LinuxX11Capture::captureSingleFrame() {
    FrameData frame;
    frame.width = width_;
    frame.height = height_;
    frame.stride = width_ * 4;
    frame.format = FrameFormat::RGBA8888;
    frame.frameNumber = ++frameCounter_;

    auto now = std::chrono::steady_clock::now().time_since_epoch();
    frame.timestampUs = std::chrono::duration_cast<std::chrono::microseconds>(now).count();

    size_t bufferSize = frame.stride * frame.height;
    frame.pixelData.resize(bufferSize);

    if (display_) {
        XImage* ximage =
            XGetImage(display_, rootWindow_, 0, 0, width_, height_, AllPlanes, ZPixmap);
        if (ximage) {
            uint8_t* dst = frame.pixelData.data();
            const uint8_t* src = reinterpret_cast<const uint8_t*>(ximage->data);
            int bpp = ximage->bits_per_pixel / 8;

            for (uint32_t y = 0; y < height_; ++y) {
                const uint8_t* srcRow = src + (y * ximage->bytes_per_line);
                uint8_t* dstRow = dst + (y * width_ * 4);
                for (uint32_t x = 0; x < width_; ++x) {
                    uint8_t b = srcRow[x * bpp + 0];
                    uint8_t g = srcRow[x * bpp + 1];
                    uint8_t r = srcRow[x * bpp + 2];
                    dstRow[x * 4 + 0] = r;
                    dstRow[x * 4 + 1] = g;
                    dstRow[x * 4 + 2] = b;
                    dstRow[x * 4 + 3] = 0xFF;
                }
            }
            XDestroyImage(ximage);

            // 1. Mirror Shield disabled per configuration - capture full desktop unmasked
            // if (cachedClientBounds_.isActive) {
            //     MirrorShield::applyMirrorShield(frame.pixelData.data(), width_, height_,
            //     cachedClientBounds_, 4);
            // }

            // 2. Dirty Region Detection: If frame is unchanged from previous frame, skip duplicate
            // transmission
            if (!prevFrameData_.empty() && prevFrameData_.size() == frame.pixelData.size()) {
                DirtyRect dirty = DirtyRegionDetector::detectDirtyRegion(prevFrameData_.data(),
                                                                         frame.pixelData.data(),
                                                                         width_,
                                                                         height_,
                                                                         4);
                if (!dirty.isDirty) {
                    // Desktop frame is static - skip duplicate send to keep latency at 0ms!
                    return std::nullopt;
                }
            }

            prevFrameData_ = frame.pixelData;
            return frame;
        }
    }

    // Software test pattern for headless CI environments
    uint32_t* pixels = reinterpret_cast<uint32_t*>(frame.pixelData.data());
    uint32_t color = 0xFF1E1E2E;
    std::fill(pixels, pixels + (width_ * height_), color);

    return frame;
}

bool LinuxX11Capture::startCapture(FrameCallback callback) {
    if (isCapturing_.load()) {
        return false;
    }

    stopRequested_.store(false);
    isCapturing_.store(true);

    captureThread_ = std::thread([this, callback]() {
        while (!stopRequested_.load()) {
            auto frameOpt = captureSingleFrame();
            if (frameOpt.has_value() && callback) {
                callback(frameOpt.value());
            }
            uint32_t targetFps = bitrateController_.getSettings().targetFps;
            uint32_t sleepMs = (targetFps > 0) ? (1000 / targetFps) : 33;
            std::this_thread::sleep_for(std::chrono::milliseconds(sleepMs));
        }
        isCapturing_.store(false);
    });

    return true;
}

void LinuxX11Capture::stopCapture() {
    stopCaptureInternal();
}

void LinuxX11Capture::stopCaptureInternal() {
    if (isCapturing_.load()) {
        stopRequested_.store(true);
        if (captureThread_.joinable()) {
            captureThread_.join();
        }
        isCapturing_.store(false);
    }
}

std::vector<MonitorInfo> LinuxX11Capture::enumerateMonitors() {
    std::vector<MonitorInfo> monitors;
    if (!display_) {
        // Fallback: report a single virtual display
        monitors.push_back({0, "Primary Display", width_, height_, 0, 0, true});
        return monitors;
    }

    // Use XRandR if available to enumerate physical monitors
    int screenCount = ScreenCount(display_);
    for (int i = 0; i < screenCount; ++i) {
        MonitorInfo info;
        info.monitorId = static_cast<uint32_t>(i);
        info.name = "Screen " + std::to_string(i);
        info.width = static_cast<uint32_t>(DisplayWidth(display_, i));
        info.height = static_cast<uint32_t>(DisplayHeight(display_, i));
        info.offsetX = 0;
        info.offsetY = 0;
        info.isPrimary = (i == DefaultScreen(display_));
        monitors.push_back(std::move(info));
    }

    if (monitors.empty()) {
        monitors.push_back({0, "Primary Display", width_, height_, 0, 0, true});
    }
    return monitors;
}

bool LinuxX11Capture::selectMonitor(uint32_t monitorId) {
    auto monitors = enumerateMonitors();
    for (const auto& mon : monitors) {
        if (mon.monitorId == monitorId) {
            activeMonitorId_ = monitorId;
            width_ = mon.width;
            height_ = mon.height;
            if (display_ && monitorId < static_cast<uint32_t>(ScreenCount(display_))) {
                rootWindow_ = RootWindow(display_, static_cast<int>(monitorId));
            }
            return true;
        }
    }
    return false;
}

std::unique_ptr<ICaptureBackend> CaptureBackendFactory::createDefaultBackend() {
    const char* display = std::getenv("DISPLAY");
    if (!display || std::strlen(display) == 0) {
        std::cout << "[CaptureFactory] Headless/Embedded environment detected ($DISPLAY unset); "
                     "instantiating Linux DRM/KMS Backend."
                  << std::endl;
        return std::make_unique<LinuxDrmCapture>();
    }
    return std::make_unique<LinuxX11Capture>();
}

} // namespace rap::capture
