#ifndef RAP_CAPTURE_MIRROR_SHIELD_H
#define RAP_CAPTURE_MIRROR_SHIELD_H

#include <cstdint>

namespace rap::capture {

struct WindowBounds {
    int x{0};
    int y{0};
    int width{0};
    int height{0};
    bool isActive{false};
};

class MirrorShield {
public:
    static bool applyMirrorShield(uint8_t* frameBuffer,
                                  int frameWidth,
                                  int frameHeight,
                                  const WindowBounds& clientBounds,
                                  int bytesPerPixel = 4);
};

} // namespace rap::capture

#endif // RAP_CAPTURE_MIRROR_SHIELD_H
