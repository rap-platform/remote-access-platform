//! Tamper-Evident Audit Logging Service crate for Remote Access Platform.
//! Implements a cryptographic SHA-256 hash chain (append-only ledger) for all auth, session, and file transfer events.

#![forbid(unsafe_code)]

pub mod notifications;

use chrono::Utc;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::sync::Arc;
use tokio::sync::RwLock;
use uuid::Uuid;

pub const GENESIS_PREV_HASH: &str =
    "0000000000000000000000000000000000000000000000000000000000000000";

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct AuditEvent {
    pub sequence_number: u64,
    pub event_id: String,
    pub timestamp: String,
    pub event_type: String,
    pub actor: String,
    pub resource: String,
    pub status: String,
    pub details: String,
    pub prev_hash: String,
    pub hash: String,
}

impl AuditEvent {
    #[allow(clippy::too_many_arguments)]
    pub fn compute_hash(
        sequence_number: u64,
        event_id: &str,
        timestamp: &str,
        event_type: &str,
        actor: &str,
        resource: &str,
        status: &str,
        details: &str,
        prev_hash: &str,
    ) -> String {
        let mut hasher = Sha256::new();
        hasher.update(sequence_number.to_be_bytes());
        hasher.update(event_id.as_bytes());
        hasher.update(timestamp.as_bytes());
        hasher.update(event_type.as_bytes());
        hasher.update(actor.as_bytes());
        hasher.update(resource.as_bytes());
        hasher.update(status.as_bytes());
        hasher.update(details.as_bytes());
        hasher.update(prev_hash.as_bytes());
        hex::encode(hasher.finalize())
    }
}

// Simple inline hex encoding helper to avoid extra dependency issues
mod hex {
    pub fn encode(bytes: impl AsRef<[u8]>) -> String {
        bytes
            .as_ref()
            .iter()
            .map(|b| format!("{:02x}", b))
            .collect()
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuditLogIntegrityReport {
    pub is_valid: bool,
    pub total_events: usize,
    pub genesis_hash: String,
    pub head_hash: String,
    pub tampered_event_id: Option<String>,
}

#[derive(Debug, Clone, Default)]
pub struct AuditLogService {
    chain: Arc<RwLock<Vec<AuditEvent>>>,
}

impl AuditLogService {
    pub fn new() -> Self {
        Self {
            chain: Arc::new(RwLock::new(Vec::new())),
        }
    }

    pub async fn log_event(
        &self,
        event_type: impl Into<String>,
        actor: impl Into<String>,
        resource: impl Into<String>,
        status: impl Into<String>,
        details: impl Into<String>,
    ) -> AuditEvent {
        let event_type = event_type.into();
        let actor = actor.into();
        let resource = resource.into();
        let status = status.into();
        let details = details.into();

        let mut chain = self.chain.write().await;
        let sequence_number = chain.len() as u64;
        let event_id = Uuid::new_v4().to_string();
        let timestamp = Utc::now().to_rfc3339();

        let prev_hash = if let Some(last_event) = chain.last() {
            last_event.hash.clone()
        } else {
            GENESIS_PREV_HASH.to_string()
        };

        let hash = AuditEvent::compute_hash(
            sequence_number,
            &event_id,
            &timestamp,
            &event_type,
            &actor,
            &resource,
            &status,
            &details,
            &prev_hash,
        );

        let event = AuditEvent {
            sequence_number,
            event_id,
            timestamp,
            event_type,
            actor,
            resource,
            status,
            details,
            prev_hash,
            hash,
        };

        chain.push(event.clone());
        event
    }

    pub async fn query_logs(
        &self,
        event_type_filter: Option<&str>,
        actor_filter: Option<&str>,
        limit: usize,
    ) -> Vec<AuditEvent> {
        let chain = self.chain.read().await;
        chain
            .iter()
            .filter(|e| {
                if let Some(et) = event_type_filter {
                    if !et.is_empty() && e.event_type != et {
                        return false;
                    }
                }
                if let Some(act) = actor_filter {
                    if !act.is_empty() && e.actor != act {
                        return false;
                    }
                }
                true
            })
            .take(if limit == 0 { usize::MAX } else { limit })
            .cloned()
            .collect()
    }

    pub async fn verify_integrity(&self) -> AuditLogIntegrityReport {
        let chain = self.chain.read().await;
        if chain.is_empty() {
            return AuditLogIntegrityReport {
                is_valid: true,
                total_events: 0,
                genesis_hash: GENESIS_PREV_HASH.to_string(),
                head_hash: GENESIS_PREV_HASH.to_string(),
                tampered_event_id: None,
            };
        }

        let mut expected_prev_hash = GENESIS_PREV_HASH.to_string();
        let head_hash = chain.last().map(|e| e.hash.clone()).unwrap_or_default();

        for event in chain.iter() {
            if event.prev_hash != expected_prev_hash {
                return AuditLogIntegrityReport {
                    is_valid: false,
                    total_events: chain.len(),
                    genesis_hash: chain[0].hash.clone(),
                    head_hash: head_hash.clone(),
                    tampered_event_id: Some(event.event_id.clone()),
                };
            }

            let computed = AuditEvent::compute_hash(
                event.sequence_number,
                &event.event_id,
                &event.timestamp,
                &event.event_type,
                &event.actor,
                &event.resource,
                &event.status,
                &event.details,
                &event.prev_hash,
            );

            if computed != event.hash {
                return AuditLogIntegrityReport {
                    is_valid: false,
                    total_events: chain.len(),
                    genesis_hash: chain[0].hash.clone(),
                    head_hash: head_hash.clone(),
                    tampered_event_id: Some(event.event_id.clone()),
                };
            }

            expected_prev_hash = event.hash.clone();
        }

        AuditLogIntegrityReport {
            is_valid: true,
            total_events: chain.len(),
            genesis_hash: chain[0].hash.clone(),
            head_hash,
            tampered_event_id: None,
        }
    }

    #[cfg(test)]
    pub async fn corrupt_entry_for_testing(&self, index: usize, new_details: &str) {
        let mut chain = self.chain.write().await;
        if index < chain.len() {
            chain[index].details = new_details.to_string();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_audit_hash_chain_creation_and_integrity() {
        let service = AuditLogService::new();

        let e1 = service
            .log_event(
                "AUTH_LOGIN",
                "admin",
                "192.168.1.100",
                "SUCCESS",
                "User login",
            )
            .await;
        let e2 = service
            .log_event(
                "FILE_UPLOAD",
                "admin",
                "/etc/config.json",
                "SUCCESS",
                "Uploaded 256KB",
            )
            .await;

        assert_eq!(e1.sequence_number, 0);
        assert_eq!(e1.prev_hash, GENESIS_PREV_HASH);
        assert_eq!(e2.sequence_number, 1);
        assert_eq!(e2.prev_hash, e1.hash);

        let report = service.verify_integrity().await;
        assert!(report.is_valid);
        assert_eq!(report.total_events, 2);
        assert!(report.tampered_event_id.is_none());
    }

    #[tokio::test]
    async fn test_audit_tamper_detection() {
        let service = AuditLogService::new();

        service
            .log_event(
                "AUTH_LOGIN",
                "admin",
                "192.168.1.100",
                "SUCCESS",
                "Normal login",
            )
            .await;
        service
            .log_event(
                "SESSION_CONNECT",
                "user1",
                "agent-001",
                "SUCCESS",
                "Connected",
            )
            .await;

        // Verify initial state
        assert!(service.verify_integrity().await.is_valid);

        // Tamper with entry 0
        service
            .corrupt_entry_for_testing(0, "TAMPERED DETAILS")
            .await;

        // Verify tampering is detected immediately
        let report = service.verify_integrity().await;
        assert!(!report.is_valid);
        assert!(report.tampered_event_id.is_some());
    }
}
