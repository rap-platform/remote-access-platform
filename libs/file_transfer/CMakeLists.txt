cmake_minimum_required(VERSION 3.16)

add_library(rap_file_transfer STATIC
    src/FileTransferEngine.cpp
)

target_include_directories(rap_file_transfer PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_compile_features(rap_file_transfer PUBLIC cxx_std_20)

if(ENABLE_TESTING OR BUILD_TESTING)
    add_executable(test_file_transfer tests/test_file_transfer.cpp)
    target_link_libraries(test_file_transfer PRIVATE rap_file_transfer)
    add_test(NAME test_file_transfer COMMAND test_file_transfer)
endif()
