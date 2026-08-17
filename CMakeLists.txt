cmake_minimum_required(VERSION 3.22)

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
option(ENABLE_HOT_RELOAD "Enable QML hot reload watcher devtool" OFF)

if(MSVC)
    add_compile_options(/W4 /WX)
else()
    add_compile_options(-Wall -Wextra -Wpedantic -Werror)
endif()

find_package(Qt6 COMPONENTS Core Test REQUIRED)

if(ENABLE_TESTING)
    enable_testing()
endif()

add_subdirectory(libs/common)
add_subdirectory(apps/client/tests/qml)
