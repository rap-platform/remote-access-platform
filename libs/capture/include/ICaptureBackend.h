#ifndef RAP_CAPTURE_I_CAPTURE_BACKEND_H
#define RAP_CAPTURE_I_CAPTURE_BACKEND_H

#include <cstdint>
#include <functional>
#include <memory>
#include <optional>
#include <string>
#include <vector>

namespace rap::capture {

enum class FrameFormat {
    Unknown = 0,
    RGBA8888 = 1,
    BGRA8888 = 2,
    NV12 = 3
};

struct FrameData {
    uint32_t width{0};
    uint32_t height{0};
    uint32_t stride{0};
    FrameFormat format{FrameFormat::RGBA8888};
    uint64_t frameNumber{0};
    uint64_t timestampUs{0};
    std::vector<uint8_t> pixelData;
};

using FrameCallback = std::function<void(const FrameData &)>;

class ICaptureBackend {
public:
    virtual ~ICaptureBackend() = default;

    virtual bool initialize() = 0;
    virtual bool startCapture(FrameCallback callback) = 0;
    virtual void stopCapture() = 0;
    virtual bool isCapturing() const = 0;
    virtual std::optional<FrameData> captureSingleFrame() = 0;
    virtual std::string backendName() const = 0;
};

class CaptureBackendFactory {
public:
    static std::unique_ptr<ICaptureBackend> createDefaultBackend();
};

} // namespace rap::capture

#endif // RAP_CAPTURE_I_CAPTURE_BACKEND_H
