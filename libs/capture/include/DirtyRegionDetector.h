#ifndef RAP_CAPTURE_DIRTY_REGION_DETECTOR_H
#define RAP_CAPTURE_DIRTY_REGION_DETECTOR_H

#include <cstdint>
#include <cstddef>


namespace rap::capture {

struct DirtyRect {
    int x{0};
    int y{0};
    int width{0};
    int height{0};
    bool isDirty{false};
};

class DirtyRegionDetector {
public:
    static DirtyRect detectDirtyRegion(const uint8_t *prevFrame,
                                       const uint8_t *currFrame,
                                       int width,
                                       int height,
                                       int bytesPerPixel = 4);
};

} // namespace rap::capture

#endif // RAP_CAPTURE_DIRTY_REGION_DETECTOR_H
