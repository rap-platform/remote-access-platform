add_library(rap_capture STATIC
    src/LinuxX11Capture.cpp
    src/LinuxX11Capture.h
    include/ICaptureBackend.h
)

target_include_directories(rap_capture PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(rap_capture PUBLIC
    Qt6::Core
)

if(ENABLE_TESTING)
    add_executable(test_capture tests/test_capture.cpp)
    target_link_libraries(test_capture PRIVATE rap_capture Qt6::Test)
    add_test(NAME test_capture COMMAND test_capture)
endif()
