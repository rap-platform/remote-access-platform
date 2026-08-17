add_library(rap_common STATIC
    logging/LogCategories.cpp
    logging/LogCategories.h
    logging/JsonLogger.cpp
    logging/JsonLogger.h
)

target_include_directories(rap_common PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(rap_common PUBLIC
    Qt6::Core
)

if(ENABLE_TESTING)
    add_executable(test_logging tests/test_logging.cpp)
    target_link_libraries(test_logging PRIVATE rap_common Qt6::Test)
    add_test(NAME test_logging COMMAND test_logging)

    add_executable(test_json_logger tests/test_json_logger.cpp)
    target_link_libraries(test_json_logger PRIVATE rap_common Qt6::Test)
    add_test(NAME test_json_logger COMMAND test_json_logger)
endif()
