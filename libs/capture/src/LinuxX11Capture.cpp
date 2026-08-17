#include "LinuxX11Capture.h"
#include "MirrorShield.h"
#include "DirtyRegionDetector.h"
#include <chrono>
#include <cstring>
#include <iostream>

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

// Helper to find client window bounds for Mirror Shield loopback severing
static WindowBounds findClientWindowBounds(Display *display, Window rootWindow) {
    WindowBounds bounds;
    if (!display || !rootWindow) return bounds;

    Window rootReturn, parentReturn, *children = nullptr;
    unsigned int numChildren = 0;

    if (XQueryTree(display, rootWindow, &rootReturn, &parentReturn, &children, &numChildren) && children) {
        for (unsigned int i = 0; i < numChildren; ++i) {
            char *windowName = nullptr;
            if (XFetchName(display, children[i], &windowName) && windowName) {
                std::string title(windowName);
                XFree(windowName);
                if (title.find("Remote Access Platform") != std::string::npos) {
                    XWindowAttributes attr;
                    if (XGetWindowAttributes(display, children[i], &attr)) {
                        bounds.x = attr.x;
                        bounds.y = attr.y;
                        bounds.width = attr.width;
                        bounds.height = attr.height;
                        bounds.isActive = true;
                        break;
                    }
                }
            }
        }
        XFree(children);
    }
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
        XImage *ximage = XGetImage(display_, rootWindow_, 0, 0, width_, height_, AllPlanes, ZPixmap);
        if (ximage) {
            uint8_t *dst = frame.pixelData.data();
            const uint8_t *src = reinterpret_cast<const uint8_t *>(ximage->data);
            int bpp = ximage->bits_per_pixel / 8;

            for (uint32_t y = 0; y < height_; ++y) {
                const uint8_t *srcRow = src + (y * ximage->bytes_per_line);
                uint8_t *dstRow = dst + (y * width_ * 4);
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

            // 1. Apply Mirror Shield: Sever optical infinite feedback loop if client viewer is running on same desktop
            WindowBounds clientBounds = findClientWindowBounds(display_, rootWindow_);
            if (clientBounds.isActive) {
                MirrorShield::applyMirrorShield(frame.pixelData.data(), width_, height_, clientBounds, 4);
            }

            // 2. Dirty Region Detection: If frame is unchanged from previous frame, skip duplicate transmission
            if (!prevFrameData_.empty() && prevFrameData_.size() == frame.pixelData.size()) {
                DirtyRect dirty = DirtyRegionDetector::detectDirtyRegion(prevFrameData_.data(), frame.pixelData.data(), width_, height_, 4);
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
    uint32_t *pixels = reinterpret_cast<uint32_t *>(frame.pixelData.data());
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
            std::this_thread::sleep_for(std::chrono::milliseconds(33)); // ~30 FPS loop
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

std::unique_ptr<ICaptureBackend> CaptureBackendFactory::createDefaultBackend() {
    return std::make_unique<LinuxX11Capture>();
}

} // namespace rap::capture
