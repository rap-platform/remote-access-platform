cmake_minimum_required(VERSION 3.22)

# Use modern OpenGL preference — prevents macOS linker from pulling in the
# deprecated/removed AGL framework on macOS 14+ (Sonoma and later).
if(POLICY CMP0072)
    cmake_policy(SET CMP0072 NEW)
endif()

project(RemoteDesktopPlatform
    VERSION 0.1.0
    LANGUAGES CXX C
)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Enable Qt AUTOMOC and AUTOUIC
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)

# LGPLv3 Dynamic Linking Compliance Rule
set(BUILD_SHARED_LIBS ON CACHE BOOL "Force dynamic linking for LGPLv3 compliance" FORCE)

option(ENABLE_TESTING "Enable test suite targets" ON)
option(ENABLE_HOT_RELOAD "Enable QML hot reload watcher devtool" ON)

if(MSVC)
    add_compile_options(/W4 /WX)
else()
    add_compile_options(-Wall -Wextra -Wpedantic -Werror)
endif()

find_package(Qt6 COMPONENTS Core Gui Qml Quick QuickControls2 QuickLayouts Network Test REQUIRED)

# macOS: suppress any remaining weak AGL framework references from Qt prebuilt libs.
# AGL was removed in macOS 14 Sonoma; -weak_framework prevents a hard linker failure.
if(APPLE)
    add_link_options(-weak_framework AGL)
endif()

if(ENABLE_TESTING)
    enable_testing()
endif()

add_subdirectory(libs/common)
add_subdirectory(libs/protocol)
add_subdirectory(libs/capture)
add_subdirectory(libs/security)
add_subdirectory(libs/input)
add_subdirectory(libs/file_transfer)
add_subdirectory(apps/client)
add_subdirectory(apps/agent)
add_subdirectory(apps/client/tests/qml)
