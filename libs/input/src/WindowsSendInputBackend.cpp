#include "../include/WindowsSendInputBackend.h"

#ifdef _WIN32
#include <windows.h>
#endif

namespace rap::input {

WindowsSendInputBackend::WindowsSendInputBackend() = default;
WindowsSendInputBackend::~WindowsSendInputBackend() = default;

bool WindowsSendInputBackend::initialize() {
    return true;
}

bool WindowsSendInputBackend::injectEvent(const InputEvent& event) {
#ifdef _WIN32
    INPUT input = {0};
    switch (event.type) {
    case InputEventType::MouseMove: {
        input.type = INPUT_MOUSE;
        input.mi.dx = (event.x * 65535) / GetSystemMetrics(SM_CXSCREEN);
        input.mi.dy = (event.y * 65535) / GetSystemMetrics(SM_CYSCREEN);
        input.mi.dwFlags = MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE;
        SendInput(1, &input, sizeof(INPUT));
        break;
    }
    case InputEventType::MouseDown: {
        input.type = INPUT_MOUSE;
        input.mi.dwFlags = (event.button == 1)   ? MOUSEEVENTF_LEFTDOWN
                           : (event.button == 3) ? MOUSEEVENTF_RIGHTDOWN
                                                 : MOUSEEVENTF_MIDDLEDOWN;
        SendInput(1, &input, sizeof(INPUT));
        break;
    }
    case InputEventType::MouseUp: {
        input.type = INPUT_MOUSE;
        input.mi.dwFlags = (event.button == 1)   ? MOUSEEVENTF_LEFTUP
                           : (event.button == 3) ? MOUSEEVENTF_RIGHTUP
                                                 : MOUSEEVENTF_MIDDLEUP;
        SendInput(1, &input, sizeof(INPUT));
        break;
    }
    case InputEventType::MouseWheel: {
        input.type = INPUT_MOUSE;
        input.mi.dwFlags = MOUSEEVENTF_WHEEL;
        input.mi.mouseData = static_cast<DWORD>(event.delta);
        SendInput(1, &input, sizeof(INPUT));
        break;
    }
    case InputEventType::KeyDown: {
        input.type = INPUT_KEYBOARD;
        input.ki.wVk = static_cast<WORD>(event.keycode);
        SendInput(1, &input, sizeof(INPUT));
        break;
    }
    case InputEventType::KeyUp: {
        input.type = INPUT_KEYBOARD;
        input.ki.wVk = static_cast<WORD>(event.keycode);
        input.ki.dwFlags = KEYEVENTF_KEYUP;
        SendInput(1, &input, sizeof(INPUT));
        break;
    }
    default:
        break;
    }
#endif
    return true;
}

} // namespace rap::input
