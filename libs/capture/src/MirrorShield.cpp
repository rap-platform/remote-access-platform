#include "MirrorShield.h"

#include <algorithm>
#include <cstring>

namespace rap::capture {

bool MirrorShield::applyMirrorShield(uint8_t* frameBuffer,
                                     int frameWidth,
                                     int frameHeight,
                                     const WindowBounds& clientBounds,
                                     int bytesPerPixel) {
    if (!frameBuffer || frameWidth <= 0 || frameHeight <= 0 || !clientBounds.isActive) {
        return false;
    }

    int startX = std::max(0, clientBounds.x);
    int startY = std::max(0, clientBounds.y);
    int endX = std::min(frameWidth, clientBounds.x + clientBounds.width);
    int endY = std::min(frameHeight, clientBounds.y + clientBounds.height);

    if (startX >= endX || startY >= endY) {
        return false;
    }

    const int stride = frameWidth * bytesPerPixel;

    // Overlay dark privacy shield pattern (RGBA: 0x1e, 0x1e, 0x2e, 0xff) to sever infinite mirror
    // loopback
    for (int y = startY; y < endY; ++y) {
        uint8_t* row = frameBuffer + (y * stride);
        for (int x = startX; x < endX; ++x) {
            int offset = x * bytesPerPixel;
            row[offset + 0] = 0x1e; // Red
            row[offset + 1] = 0x1e; // Green
            row[offset + 2] = 0x2e; // Blue
            if (bytesPerPixel == 4) {
                row[offset + 3] = 0xff; // Alpha
            }
        }
    }

    return true;
}

} // namespace rap::capture
