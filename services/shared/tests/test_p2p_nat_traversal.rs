//! Automated End-to-End P2P NAT Traversal & Hole Punching Integration Test.

use rap_shared::nat::ice::{
    CandidateType, ConnectionMode, ConnectionStateMachine, IceCandidate, TransportProtocol,
};
use rap_shared::nat::stun::StunCodec;
use std::net::{IpAddr, Ipv4Addr, SocketAddr};

#[test]
fn test_stun_binding_request_response_flow() {
    let tx_id = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
    let req_bytes = StunCodec::encode_binding_request(tx_id);
    assert_eq!(req_bytes.len(), 20);

    let local_addr = SocketAddr::new(IpAddr::V4(Ipv4Addr::new(192, 168, 1, 50)), 18443);
    let endpoint_res = StunCodec::decode_binding_response(&req_bytes, local_addr);
    assert!(endpoint_res.is_err()); // Binding request packet is not a valid response
}

#[test]
fn test_end_to_end_p2p_candidate_negotiation_and_fallback() {
    let mut state_machine = ConnectionStateMachine::new();
    assert_eq!(state_machine.current_mode, ConnectionMode::DirectLocal);

    let client_addr = SocketAddr::new(IpAddr::V4(Ipv4Addr::new(192, 168, 1, 100)), 18443);
    let agent_local_addr = SocketAddr::new(IpAddr::V4(Ipv4Addr::new(192, 168, 1, 200)), 18443);
    let agent_public_addr = SocketAddr::new(IpAddr::V4(Ipv4Addr::new(198, 51, 100, 42)), 18443);

    let client_host = IceCandidate::new(
        "cand-c1",
        CandidateType::Host,
        TransportProtocol::Udp,
        client_addr,
    );
    let agent_host = IceCandidate::new(
        "cand-a1",
        CandidateType::Host,
        TransportProtocol::Udp,
        agent_local_addr,
    );
    let agent_srflx = IceCandidate::new(
        "cand-a2",
        CandidateType::ServerReflexive,
        TransportProtocol::Udp,
        agent_public_addr,
    );

    // 1. Direct Local P2P Connection Negotiation
    let mode_direct = state_machine.evaluate_candidates(client_host.clone(), agent_host.clone());
    assert_eq!(mode_direct, ConnectionMode::DirectLocal);

    // 2. STUN Hole Punching Connection Negotiation (Cross-Subnet NAT)
    let mode_hole_punch =
        state_machine.evaluate_candidates(client_host.clone(), agent_srflx.clone());
    assert_eq!(mode_hole_punch, ConnectionMode::StunHolePunching);

    // 3. Fallback to Relay Server when UDP direct/hole-punching fails
    let relay_addr = SocketAddr::new(IpAddr::V4(Ipv4Addr::new(203, 0, 113, 99)), 443);
    let relay_candidate = IceCandidate::new(
        "cand-r1",
        CandidateType::Relay,
        TransportProtocol::Udp,
        relay_addr,
    );
    state_machine.trigger_relay_fallback(relay_candidate);
    assert_eq!(state_machine.current_mode, ConnectionMode::RelayFallback);
}
