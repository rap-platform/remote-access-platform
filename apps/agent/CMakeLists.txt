add_executable(rap-agent
    src/main.cpp
)

target_link_libraries(rap-agent PRIVATE
    Qt6::Core
    Qt6::Network
    rap_common
    rap_protocol
    rap_capture
)
