add_library(rap_protocol STATIC
    src/ProtocolCodec.cpp
    include/ProtocolCodec.h
)

target_include_directories(rap_protocol PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(rap_protocol PUBLIC
    Qt6::Core
)

if(ENABLE_TESTING)
    add_executable(test_protocol tests/test_protocol.cpp)
    target_link_libraries(test_protocol PRIVATE rap_protocol Qt6::Test)
    add_test(NAME test_protocol COMMAND test_protocol)

    add_executable(test_protocol_fuzz fuzz/fuzz_runner.cpp)
    target_link_libraries(test_protocol_fuzz PRIVATE rap_protocol Qt6::Test)
    add_test(NAME test_protocol_fuzz COMMAND test_protocol_fuzz)
endif()
