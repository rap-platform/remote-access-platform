add_library(rap_security STATIC
    src/CryptoEngine.cpp
    include/CryptoEngine.h
)

target_include_directories(rap_security PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(rap_security PUBLIC
    Qt6::Core
)

if(ENABLE_TESTING)
    add_executable(test_crypto tests/test_crypto.cpp)
    target_link_libraries(test_crypto PRIVATE rap_security Qt6::Test)
    add_test(NAME test_crypto COMMAND test_crypto)
endif()
