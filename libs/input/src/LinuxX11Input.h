#ifndef RAP_INPUT_LINUX_X11_INPUT_H
#define RAP_INPUT_LINUX_X11_INPUT_H

#include <X11/Xlib.h>
#include <X11/extensions/XTest.h>

#include "IInputBackend.h"

namespace rap::input {

class LinuxX11Input : public IInputBackend {
public:
    LinuxX11Input() = default;
    ~LinuxX11Input() override;

    bool initialize() override;
    bool injectEvent(const InputEvent& event) override;
    std::string backendName() const override { return "Linux X11 Input Injection Backend"; }

private:
    Display* display_{nullptr};
    bool xtestSupported_{false};
};

} // namespace rap::input

#endif // RAP_INPUT_LINUX_X11_INPUT_H
