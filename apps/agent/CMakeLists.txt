add_executable(rap-agent
    src/main.cpp
)

target_link_libraries(rap-agent PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Network
    Qt6::Qml
    Qt6::Quick
    rap_common
    rap_protocol
    rap_capture
    rap_security
    rap_input
    rap_file_transfer
)
