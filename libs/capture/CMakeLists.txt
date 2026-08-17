find_package(X11 REQUIRED)

add_library(rap_capture STATIC
    src/LinuxX11Capture.cpp
    src/LinuxDrmCapture.cpp
    src/DirtyRegionDetector.cpp
    src/MirrorShield.cpp
    src/AdaptiveBitrateController.cpp
    src/LinuxX11Capture.h
    include/LinuxDrmCapture.h
    include/ICaptureBackend.h
    include/DirtyRegionDetector.h
    include/MirrorShield.h
    include/AdaptiveBitrateController.h
)

target_include_directories(rap_capture PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${X11_INCLUDE_DIR}
)

target_link_libraries(rap_capture PUBLIC
    Qt6::Core
    ${X11_LIBRARIES}
)

if(ENABLE_TESTING)
    add_executable(test_capture tests/test_capture.cpp)
    target_link_libraries(test_capture PRIVATE rap_capture Qt6::Test ${X11_LIBRARIES})
    add_test(NAME test_capture COMMAND test_capture)

    add_executable(test_performance tests/test_performance.cpp)
    target_link_libraries(test_performance PRIVATE rap_capture Qt6::Test ${X11_LIBRARIES})
    add_test(NAME test_performance COMMAND test_performance)
endif()
