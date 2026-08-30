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

add_executable(rap-client
    src/main.cpp
    src/VideoFrameProvider.cpp
    src/VideoFrameProvider.h
    src/SessionClient.cpp
    src/SessionClient.h
    src/theme/ThemeManager.cpp
    include/ThemeManager.h

    # QML Interface Sources (Visible in Qt Creator Project Tree & Indexed for Search)
    qml/Main.qml
    qml/components/HeaderBar.qml
    qml/components/IncomingConnectionDialog.qml
    qml/components/SidebarNav.qml
    qml/components/StatusBar.qml
    qml/components/ToastNotification.qml
    qml/theme/Metrics.qml
    qml/theme/Tokens.qml
    qml/theme/Typography.qml
    qml/theme/qmldir
    qml/views/DesktopSessionView.qml
    qml/views/FileTransferView.qml
    qml/views/SavedDevicesView.qml
    qml/views/SecurityKeysView.qml
    qml/views/SettingsView.qml
)

# Copy QML directory to output build folder for standalone execution
add_custom_target(copy_qml_files ALL
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_CURRENT_SOURCE_DIR}/qml
        $<TARGET_FILE_DIR:rap-client>/qml
    COMMENT "Copying QML files to binary directory"
)
add_dependencies(rap-client copy_qml_files)

target_include_directories(rap-client PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(rap-client PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::QuickLayouts
    Qt6::Network
    rap_common
    rap_protocol
    rap_security
    rap_input
    rap_file_transfer
)

if(ENABLE_HOT_RELOAD)
    target_link_libraries(rap-client PRIVATE rap_client_dev)
    target_compile_definitions(rap-client PRIVATE ENABLE_HOT_RELOAD)
endif()
