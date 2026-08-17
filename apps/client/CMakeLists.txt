if(ENABLE_HOT_RELOAD)
    add_library(rap_client_dev STATIC
        src/dev/HotReloadManager.cpp
        src/dev/HotReloadManager.h
    )

    target_include_directories(rap_client_dev PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/src
    )

    target_link_libraries(rap_client_dev PUBLIC
        Qt6::Core
        Qt6::Qml
    )

    if(ENABLE_TESTING)
        add_executable(test_hot_reload tests/test_hot_reload.cpp)
        target_link_libraries(test_hot_reload PRIVATE rap_client_dev Qt6::Test)
        add_test(NAME test_hot_reload COMMAND test_hot_reload)
    endif()
endif()
