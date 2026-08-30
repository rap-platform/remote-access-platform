#ifndef RAP_INPUT_WINDOWS_SEND_INPUT_BACKEND_H
#define RAP_INPUT_WINDOWS_SEND_INPUT_BACKEND_H

#include "IInputBackend.h"

namespace rap::input {

class WindowsSendInputBackend : public IInputBackend {
public:
    WindowsSendInputBackend();
    ~WindowsSendInputBackend() override;

    bool initialize() override;
    bool injectEvent(const InputEvent& event) override;
    std::string backendName() const override { return "Windows SendInput Injection"; }
};

} // namespace rap::input

#endif // RAP_INPUT_WINDOWS_SEND_INPUT_BACKEND_H
