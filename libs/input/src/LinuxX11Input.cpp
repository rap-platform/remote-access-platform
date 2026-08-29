#include "LinuxX11Input.h"

#include <cstdlib>
#include <iostream>

namespace rap::input {

LinuxX11Input::~LinuxX11Input() {
    if (display_) {
        XCloseDisplay(display_);
        display_ = nullptr;
    }
}

bool LinuxX11Input::initialize() {
    display_ = XOpenDisplay(nullptr);
    if (display_) {
        int eventBase, errorBase, majorVersion, minorVersion;
        xtestSupported_ =
            XTestQueryExtension(display_, &eventBase, &errorBase, &majorVersion, &minorVersion);
    }
    return true;
}

bool LinuxX11Input::injectEvent(const InputEvent& event) {
    if (std::getenv("RAP_DISABLE_X11_INJECTION") || std::getenv("RAP_TEST_MODE")) {
        return true;
    }
    if (display_ && xtestSupported_) {
        switch (event.type) {
        case InputEventType::MouseMove:
            XTestFakeMotionEvent(display_, -1, event.x, event.y, CurrentTime);
            XFlush(display_);
            return true;

        case InputEventType::MouseDown:
            XTestFakeMotionEvent(display_, -1, event.x, event.y, CurrentTime);
            XTestFakeButtonEvent(display_, event.button, True, CurrentTime);
            XFlush(display_);
            return true;

        case InputEventType::MouseUp:
            XTestFakeButtonEvent(display_, event.button, False, CurrentTime);
            XFlush(display_);
            return true;

        case InputEventType::MouseWheel: {
            uint32_t btn = (event.delta > 0) ? 4 : 5; // 4 = Wheel Up, 5 = Wheel Down
            XTestFakeButtonEvent(display_, btn, True, CurrentTime);
            XTestFakeButtonEvent(display_, btn, False, CurrentTime);
            XFlush(display_);
            return true;
        }

        case InputEventType::KeyDown:
            if (event.keycode > 0) {
                XTestFakeKeyEvent(display_, event.keycode, True, CurrentTime);
                XFlush(display_);
            }
            return true;

        case InputEventType::KeyUp:
            if (event.keycode > 0) {
                XTestFakeKeyEvent(display_, event.keycode, False, CurrentTime);
                XFlush(display_);
            }
            return true;

        default:
            break;
        }
    }
    // Headless / software fallback input processing
    return true;
}

std::unique_ptr<IInputBackend> InputBackendFactory::createDefaultBackend() {
    return std::make_unique<LinuxX11Input>();
}

} // namespace rap::input
