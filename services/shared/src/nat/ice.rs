//! ICE-lite UDP hole punching and fallback connection state machine.
#![forbid(unsafe_code)]

use serde::{Deserialize, Serialize};
use std::net::SocketAddr;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum CandidateType {
    Host,
    ServerReflexive,
    Relay,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum TransportProtocol {
    Udp,
    Tcp,
}

/// ICE candidate descriptor used during peer connectivity negotiation.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct IceCandidate {
    pub candidate_id: String,
    pub candidate_type: CandidateType,
    pub protocol: TransportProtocol,
    pub endpoint: SocketAddr,
    pub priority: u32,
    pub foundation: String,
}

impl IceCandidate {
    pub fn new(
        candidate_id: impl Into<String>,
        candidate_type: CandidateType,
        protocol: TransportProtocol,
        endpoint: SocketAddr,
    ) -> Self {
        let type_preference = match candidate_type {
            CandidateType::Host => 126,
            CandidateType::ServerReflexive => 100,
            CandidateType::Relay => 0,
        };
        let local_preference = 65535;
        let component_id = 1;
        let priority =
            (1 << 24) * type_preference + (1 << 8) * local_preference + (256 - component_id);

        Self {
            candidate_id: candidate_id.into(),
            candidate_type,
            protocol,
            endpoint,
            priority,
            foundation: format!("fnd-{}", endpoint.port()),
        }
    }
}

/// Active connection state machine tracking P2P direct -> STUN hole-punching -> Relay fallback.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum ConnectionMode {
    DirectLocal,
    StunHolePunching,
    RelayFallback,
    Failed,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConnectionStateMachine {
    pub current_mode: ConnectionMode,
    pub selected_pair: Option<(IceCandidate, IceCandidate)>,
    pub attempts: u32,
}

impl Default for ConnectionStateMachine {
    fn default() -> Self {
        Self {
            current_mode: ConnectionMode::DirectLocal,
            selected_pair: None,
            attempts: 0,
        }
    }
}

impl ConnectionStateMachine {
    pub fn new() -> Self {
        Self::default()
    }

    /// Attempt peer connectivity evaluation over candidate pairs.
    pub fn evaluate_candidates(
        &mut self,
        local_candidate: IceCandidate,
        remote_candidate: IceCandidate,
    ) -> ConnectionMode {
        self.attempts += 1;

        if local_candidate.candidate_type == CandidateType::Host
            && remote_candidate.candidate_type == CandidateType::Host
        {
            self.current_mode = ConnectionMode::DirectLocal;
            self.selected_pair = Some((local_candidate, remote_candidate));
        } else if local_candidate.candidate_type == CandidateType::ServerReflexive
            || remote_candidate.candidate_type == CandidateType::ServerReflexive
        {
            self.current_mode = ConnectionMode::StunHolePunching;
            self.selected_pair = Some((local_candidate, remote_candidate));
        } else {
            self.current_mode = ConnectionMode::RelayFallback;
            self.selected_pair = Some((local_candidate, remote_candidate));
        }

        self.current_mode.clone()
    }

    /// Trigger explicit fallback to relay server if UDP hole punching fails.
    pub fn trigger_relay_fallback(&mut self, relay_candidate: IceCandidate) {
        self.current_mode = ConnectionMode::RelayFallback;
        if let Some((ref mut local, _)) = self.selected_pair {
            *local = relay_candidate;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::net::{IpAddr, Ipv4Addr};

    #[test]
    fn test_ice_candidate_priority_calculation() {
        let addr = SocketAddr::new(IpAddr::V4(Ipv4Addr::new(127, 0, 0, 1)), 18443);
        let host_cand =
            IceCandidate::new("cand1", CandidateType::Host, TransportProtocol::Udp, addr);
        let srflx_cand = IceCandidate::new(
            "cand2",
            CandidateType::ServerReflexive,
            TransportProtocol::Udp,
            addr,
        );

        assert!(host_cand.priority > srflx_cand.priority);
    }

    #[test]
    fn test_connection_state_machine_transitions() {
        let mut sm = ConnectionStateMachine::new();
        assert_eq!(sm.current_mode, ConnectionMode::DirectLocal);

        let addr1 = SocketAddr::new(IpAddr::V4(Ipv4Addr::new(192, 168, 1, 10)), 18443);
        let addr2 = SocketAddr::new(IpAddr::V4(Ipv4Addr::new(203, 0, 113, 5)), 18443);

        let host = IceCandidate::new("c1", CandidateType::Host, TransportProtocol::Udp, addr1);
        let srflx = IceCandidate::new(
            "c2",
            CandidateType::ServerReflexive,
            TransportProtocol::Udp,
            addr2,
        );

        let mode = sm.evaluate_candidates(host.clone(), srflx.clone());
        assert_eq!(mode, ConnectionMode::StunHolePunching);

        sm.trigger_relay_fallback(IceCandidate::new(
            "c3",
            CandidateType::Relay,
            TransportProtocol::Udp,
            addr2,
        ));
        assert_eq!(sm.current_mode, ConnectionMode::RelayFallback);
    }
}
