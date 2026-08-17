#include "DirtyRegionDetector.h"
#include <algorithm>
#include <cstring>

namespace rap::capture {

DirtyRect DirtyRegionDetector::detectDirtyRegion(const uint8_t *prevFrame,
                                                   const uint8_t *currFrame,
                                                   int width,
                                                   int height,
                                                   int bytesPerPixel) {
    DirtyRect rect;
    if (!currFrame || width <= 0 || height <= 0) {
        return rect;
    }

    if (!prevFrame) {
        rect.x = 0;
        rect.y = 0;
        rect.width = width;
        rect.height = height;
        rect.isDirty = true;
        return rect;
    }

    int minX = width;
    int minY = height;
    int maxX = -1;
    int maxY = -1;

    const int stride = width * bytesPerPixel;

    for (int y = 0; y < height; y += 2) { // Sub-sampled 2-line scan for sub-ms execution
        const uint8_t *prevRow = prevFrame + (y * stride);
        const uint8_t *currRow = currFrame + (y * stride);

        for (int x = 0; x < width; x += 4) { // Sub-sampled 4-pixel step
            const int offset = x * bytesPerPixel;
            if (std::memcmp(prevRow + offset, currRow + offset, bytesPerPixel) != 0) {
                minX = std::min(minX, x);
                maxX = std::max(maxX, x + 4);
                minY = std::min(minY, y);
                maxY = std::max(maxY, y + 2);
            }
        }
    }

    if (maxX >= minX && maxY >= minY) {
        rect.x = minX;
        rect.y = minY;
        rect.width = std::min(width - minX, maxX - minX);
        rect.height = std::min(height - minY, maxY - minY);
        rect.isDirty = true;
    }

    return rect;
}

} // namespace rap::capture
