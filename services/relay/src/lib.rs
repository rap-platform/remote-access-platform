//! High-throughput stateless UDP/QUIC data plane packet relay service crate.
#![forbid(unsafe_code)]

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::net::SocketAddr;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;
use tokio::sync::RwLock;

/// Active relay pairing mapping client endpoint to host agent endpoint.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RelayPair {
    pub session_id: String,
    pub client_endpoint: Option<SocketAddr>,
    pub agent_endpoint: Option<SocketAddr>,
    pub created_at_ms: u64,
}

/// Real-time metrics for relay server monitoring.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct RelayMetrics {
    pub active_sessions: usize,
    pub total_packets_relayed: u64,
    pub total_bytes_relayed: u64,
}

/// Stateless Zero-Decryption Packet Relay Core Engine.
#[derive(Clone, Default)]
pub struct RelayServer {
    sessions: Arc<RwLock<HashMap<String, RelayPair>>>,
    packets_relayed: Arc<AtomicU64>,
    bytes_relayed: Arc<AtomicU64>,
}

impl RelayServer {
    pub fn new() -> Self {
        Self::default()
    }

    /// Register or update a peer endpoint (client or agent) for a given session ID.
    pub async fn register_peer(&self, session_id: String, endpoint: SocketAddr, is_agent: bool) {
        let mut guard = self.sessions.write().await;
        let entry = guard
            .entry(session_id.clone())
            .or_insert_with(|| RelayPair {
                session_id,
                client_endpoint: None,
                agent_endpoint: None,
                created_at_ms: chrono::Utc::now().timestamp_millis() as u64,
            });

        if is_agent {
            entry.agent_endpoint = Some(endpoint);
        } else {
            entry.client_endpoint = Some(endpoint);
        }
    }

    /// Route incoming raw binary packet to destination peer with zero payload decryption.
    pub async fn route_packet(
        &self,
        session_id: &str,
        sender_addr: SocketAddr,
        packet_bytes: &[u8],
    ) -> Option<SocketAddr> {
        let guard = self.sessions.read().await;
        if let Some(pair) = guard.get(session_id) {
            let target_endpoint = if Some(sender_addr) == pair.client_endpoint {
                pair.agent_endpoint
            } else if Some(sender_addr) == pair.agent_endpoint {
                pair.client_endpoint
            } else {
                // If sender matches neither explicitly, route to whichever peer is configured
                pair.agent_endpoint.or(pair.client_endpoint)
            };

            if target_endpoint.is_some() {
                self.packets_relayed.fetch_add(1, Ordering::Relaxed);
                self.bytes_relayed
                    .fetch_add(packet_bytes.len() as u64, Ordering::Relaxed);
            }
            target_endpoint
        } else {
            None
        }
    }

    /// Terminate and remove a relay session pair.
    pub async fn remove_session(&self, session_id: &str) -> bool {
        let mut guard = self.sessions.write().await;
        guard.remove(session_id).is_some()
    }

    /// Retrieve live relay engine telemetry & throughput statistics.
    pub async fn get_metrics(&self) -> RelayMetrics {
        let guard = self.sessions.read().await;
        RelayMetrics {
            active_sessions: guard.len(),
            total_packets_relayed: self.packets_relayed.load(Ordering::Relaxed),
            total_bytes_relayed: self.bytes_relayed.load(Ordering::Relaxed),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::net::{IpAddr, Ipv4Addr};

    #[tokio::test]
    async fn test_relay_session_pairing_and_zero_decryption_routing() {
        let relay = RelayServer::new();
        let session_id = "rap-sess-relay-100".to_string();

        let client_addr = SocketAddr::new(IpAddr::V4(Ipv4Addr::new(192, 168, 1, 10)), 50001);
        let agent_addr = SocketAddr::new(IpAddr::V4(Ipv4Addr::new(10, 0, 0, 20)), 18443);

        // Register client & agent endpoints
        relay
            .register_peer(session_id.clone(), client_addr, false)
            .await;
        relay
            .register_peer(session_id.clone(), agent_addr, true)
            .await;

        // Simulated encrypted binary packet payload
        let mock_encrypted_payload =
            vec![0x52, 0x41, 0x50, 0x30, 0x01, 0x02, 0x03, 0x04, 0xff, 0xfe];

        // Forward packet from client -> agent
        let target_for_client = relay
            .route_packet(&session_id, client_addr, &mock_encrypted_payload)
            .await;
        assert_eq!(target_for_client, Some(agent_addr));

        // Forward packet from agent -> client
        let target_for_agent = relay
            .route_packet(&session_id, agent_addr, &mock_encrypted_payload)
            .await;
        assert_eq!(target_for_agent, Some(client_addr));

        // Verify telemetry metrics
        let metrics = relay.get_metrics().await;
        assert_eq!(metrics.active_sessions, 1);
        assert_eq!(metrics.total_packets_relayed, 2);
        assert_eq!(
            metrics.total_bytes_relayed,
            (mock_encrypted_payload.len() * 2) as u64
        );
    }
}
