//! Session signaling and rendezvous service crate.
#![forbid(unsafe_code)]

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use uuid::Uuid;

/// Signaling message type envelope exchanged over WebSockets or QUIC streams.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(tag = "type", content = "payload")]
pub enum SignalingMessage {
    PeerRegister {
        device_id: String,
        auth_token: String,
        is_agent: bool,
    },
    SessionInitiate {
        target_device_id: String,
        client_public_key_hex: String,
    },
    SessionAccept {
        session_id: String,
        agent_public_key_hex: String,
        relay_endpoint: Option<String>,
    },
    CandidateExchange {
        session_id: String,
        candidate_sdp: String,
    },
    SessionClose {
        session_id: String,
    },
    Error {
        code: u16,
        message: String,
    },
}

/// Active desktop session state tracked in Control Plane rendezvous service.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum SessionStatus {
    Initiated,
    Active,
    Terminated,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SignalingSession {
    pub session_id: String,
    pub client_device_id: String,
    pub agent_device_id: String,
    pub client_public_key_hex: String,
    pub agent_public_key_hex: Option<String>,
    pub status: SessionStatus,
    pub created_at_ms: u64,
}

/// Thread-safe Rendezvous & Signaling Server implementation.
#[derive(Clone, Default)]
pub struct SignalingServer {
    online_peers: Arc<RwLock<HashMap<String, bool>>>, // device_id -> is_agent
    active_sessions: Arc<RwLock<HashMap<String, SignalingSession>>>, // session_id -> SignalingSession
}

impl SignalingServer {
    pub fn new() -> Self {
        Self::default()
    }

    /// Register a peer (host agent or desktop client viewer) as online in rendezvous cache.
    pub async fn register_peer(&self, device_id: String, is_agent: bool) {
        self.online_peers.write().await.insert(device_id, is_agent);
    }

    /// Check if target host agent device is currently registered and online.
    pub async fn is_peer_online(&self, device_id: &str) -> bool {
        let peers = self.online_peers.read().await;
        *peers.get(device_id).unwrap_or(&false)
    }

    /// Initiate a new remote desktop signaling session between client and target agent.
    pub async fn initiate_session(
        &self,
        client_device_id: String,
        target_agent_id: String,
        client_public_key_hex: String,
    ) -> Result<SignalingSession, String> {
        if !self.is_peer_online(&target_agent_id).await {
            return Err(format!(
                "Target agent device {} is offline or not registered",
                target_agent_id
            ));
        }

        let session_id = format!("rap-sess-{}", Uuid::new_v4().simple());
        let now_ms = chrono::Utc::now().timestamp_millis() as u64;

        let session = SignalingSession {
            session_id: session_id.clone(),
            client_device_id,
            agent_device_id: target_agent_id,
            client_public_key_hex,
            agent_public_key_hex: None,
            status: SessionStatus::Initiated,
            created_at_ms: now_ms,
        };

        self.active_sessions
            .write()
            .await
            .insert(session_id, session.clone());
        Ok(session)
    }

    /// Accept remote session on host agent side with agent X25519 public key.
    pub async fn accept_session(
        &self,
        session_id: &str,
        agent_public_key_hex: String,
    ) -> Result<SignalingSession, String> {
        let mut sessions = self.active_sessions.write().await;
        if let Some(session) = sessions.get_mut(session_id) {
            session.agent_public_key_hex = Some(agent_public_key_hex);
            session.status = SessionStatus::Active;
            Ok(session.clone())
        } else {
            Err(format!("Session {} not found", session_id))
        }
    }

    /// Terminate active session and cleanup signaling resources.
    pub async fn close_session(&self, session_id: &str) -> bool {
        let mut sessions = self.active_sessions.write().await;
        if let Some(session) = sessions.get_mut(session_id) {
            session.status = SessionStatus::Terminated;
            true
        } else {
            false
        }
    }

    /// Retrieve active session state.
    pub async fn get_session(&self, session_id: &str) -> Option<SignalingSession> {
        let sessions = self.active_sessions.read().await;
        sessions.get(session_id).cloned()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_signaling_session_lifecycle() {
        let server = SignalingServer::new();

        let agent_id = "rap-dev-agent-001".to_string();
        let client_id = "rap-dev-client-002".to_string();

        // Register agent as online
        server.register_peer(agent_id.clone(), true).await;
        assert!(server.is_peer_online(&agent_id).await);
        assert!(!server.is_peer_online("unknown-device").await);

        // Initiate signaling session
        let initiate_res = server
            .initiate_session(
                client_id.clone(),
                agent_id.clone(),
                "0102030405060708090a0b0c0d0e0f10".into(),
            )
            .await;
        assert!(initiate_res.is_ok());
        let session = initiate_res.expect("Session initiation should succeed");
        assert_eq!(session.status, SessionStatus::Initiated);

        // Accept session from agent side
        let accept_res = server
            .accept_session(
                &session.session_id,
                "100f0e0d0c0b0a090807060504030201".into(),
            )
            .await;
        assert!(accept_res.is_ok());
        let active_sess = accept_res.expect("Session acceptance should succeed");
        assert_eq!(active_sess.status, SessionStatus::Active);
        assert!(active_sess.agent_public_key_hex.is_some());

        // Close session
        let closed = server.close_session(&session.session_id).await;
        assert!(closed);
        let final_sess = server
            .get_session(&session.session_id)
            .await
            .expect("Session should exist");
        assert_eq!(final_sess.status, SessionStatus::Terminated);
    }
}
