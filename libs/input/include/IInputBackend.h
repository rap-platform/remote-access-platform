#ifndef RAP_INPUT_I_INPUT_BACKEND_H
#define RAP_INPUT_I_INPUT_BACKEND_H

#include <cstdint>
#include <memory>
#include <string>

namespace rap::input {

enum class InputEventType : uint16_t {
    Unknown = 0,
    MouseMove = 1,
    MouseDown = 2,
    MouseUp = 3,
    MouseWheel = 4,
    KeyDown = 5,
    KeyUp = 6
};

struct InputEvent {
    InputEventType type{InputEventType::Unknown};
    int32_t x{0};
    int32_t y{0};
    uint32_t button{0};    // 1 = Left, 2 = Middle, 3 = Right
    int32_t delta{0};      // Scroll wheel delta
    uint32_t keycode{0};   // Key code
    uint32_t modifiers{0}; // Shift, Ctrl, Alt state
};

class IInputBackend {
public:
    virtual ~IInputBackend() = default;

    virtual bool initialize() = 0;
    virtual bool injectEvent(const InputEvent& event) = 0;
    virtual std::string backendName() const = 0;
};

class InputBackendFactory {
public:
    static std::unique_ptr<IInputBackend> createDefaultBackend();
};

#ifndef __linux__
class CrossPlatformDummyInput : public IInputBackend {
public:
    bool initialize() override { return true; }
    bool injectEvent(const InputEvent&) override { return true; }
    std::string backendName() const override { return "CrossPlatform Stub Input"; }
};

inline std::unique_ptr<IInputBackend> InputBackendFactory::createDefaultBackend() {
    return std::make_unique<CrossPlatformDummyInput>();
}
#endif

} // namespace rap::input

#endif // RAP_INPUT_I_INPUT_BACKEND_H
