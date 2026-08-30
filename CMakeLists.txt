cmake_minimum_required(VERSION 3.22)

# Use modern OpenGL preference — prevents macOS linker from pulling in the
# deprecated/removed AGL framework on macOS 14+ (Sonoma and later).
if(POLICY CMP0072)
    cmake_policy(SET CMP0072 NEW)
endif()

# Read version from central VERSION file
set(APP_VERSION "0.3.0")
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/VERSION")
    file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/VERSION" VERSION_LINE REGEX "^AppVersion=")
    if(VERSION_LINE)
        string(REGEX REPLACE "^AppVersion=" "" APP_VERSION "${VERSION_LINE}")
        string(STRIP "${APP_VERSION}" APP_VERSION)
    endif()
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/VERSION")
endif()

project(RemoteDesktopPlatform
    VERSION ${APP_VERSION}
    LANGUAGES CXX C
)

add_compile_definitions(APP_VERSION="${APP_VERSION}")

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
