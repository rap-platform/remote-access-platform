if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    find_package(X11 REQUIRED)

    add_library(rap_input STATIC
        src/LinuxX11Input.cpp
        src/LinuxX11Input.h
        include/IInputBackend.h
    )

    target_include_directories(rap_input PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        ${X11_INCLUDE_DIR}
    )

    target_link_libraries(rap_input PUBLIC
        Qt6::Core
        ${X11_LIBRARIES}
        Xtst
    )

    if(ENABLE_TESTING)
        add_executable(test_input tests/test_input.cpp)
        target_link_libraries(test_input PRIVATE rap_input Qt6::Test ${X11_LIBRARIES} Xtst)
        add_test(NAME test_input COMMAND test_input)
    endif()
else()
    add_library(rap_input STATIC
        src/WindowsSendInputBackend.cpp
        include/IInputBackend.h
        include/WindowsSendInputBackend.h
    )
    target_include_directories(rap_input PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
endif()
