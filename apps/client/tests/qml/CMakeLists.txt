if(ENABLE_TESTING)
    find_package(Qt6 COMPONENTS QuickTest REQUIRED)

    add_executable(test_qml_skeleton main.cpp tst_dummy.qml)
    target_link_libraries(test_qml_skeleton PRIVATE Qt6::QuickTest)
    add_test(NAME test_qml_skeleton COMMAND test_qml_skeleton -input ${CMAKE_CURRENT_SOURCE_DIR})
endif()
