//! Device identity and registration service crate.
#![forbid(unsafe_code)]

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use uuid::Uuid;

/// Registered remote desktop device metadata.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Device {
    pub device_id: String,
    pub hostname: String,
    pub os_name: String,
    pub public_key_hex: String,
    pub auth_token: String,
    pub created_at_ms: u64,
    pub last_seen_ms: u64,
    pub is_online: bool,
}

/// Request structure for registering a new host agent or client device.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RegistrationRequest {
    pub hostname: String,
    pub os_name: String,
    pub public_key_hex: String,
}

/// Response structure returned after successful device registration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RegistrationResponse {
    pub success: bool,
    pub device_id: String,
    pub auth_token: String,
    pub message: String,
}

/// Thread-safe Device Identity Management Service.
#[derive(Clone, Default)]
pub struct IdentityService {
    devices: Arc<RwLock<HashMap<String, Device>>>,
    tokens: Arc<RwLock<HashMap<String, String>>>, // Token -> DeviceID
}

impl IdentityService {
    pub fn new() -> Self {
        Self::default()
    }

    /// Register a new host agent or client device in the control plane identity store.
    pub async fn register_device(&self, req: RegistrationRequest) -> RegistrationResponse {
        let device_id = format!("rap-dev-{}", Uuid::new_v4().simple());
        let auth_token = format!("rap-token-{}", Uuid::new_v4().simple());
        let now_ms = chrono::Utc::now().timestamp_millis() as u64;

        let device = Device {
            device_id: device_id.clone(),
            hostname: req.hostname,
            os_name: req.os_name,
            public_key_hex: req.public_key_hex,
            auth_token: auth_token.clone(),
            created_at_ms: now_ms,
            last_seen_ms: now_ms,
            is_online: true,
        };

        self.devices.write().await.insert(device_id.clone(), device);
        self.tokens
            .write()
            .await
            .insert(auth_token.clone(), device_id.clone());

        RegistrationResponse {
            success: true,
            device_id,
            auth_token,
            message: "Device successfully registered in Control Plane".into(),
        }
    }

    /// Authenticate incoming device request using its issued authorization token.
    pub async fn authenticate(&self, auth_token: &str) -> Option<Device> {
        let tokens_guard = self.tokens.read().await;
        if let Some(device_id) = tokens_guard.get(auth_token) {
            let devices_guard = self.devices.read().await;
            devices_guard.get(device_id).cloned()
        } else {
            None
        }
    }

    /// Update device online presence status.
    pub async fn set_presence(&self, device_id: &str, is_online: bool) -> bool {
        let mut devices_guard = self.devices.write().await;
        if let Some(device) = devices_guard.get_mut(device_id) {
            device.is_online = is_online;
            device.last_seen_ms = chrono::Utc::now().timestamp_millis() as u64;
            true
        } else {
            false
        }
    }

    /// Lookup device metadata by device ID.
    pub async fn get_device(&self, device_id: &str) -> Option<Device> {
        let devices_guard = self.devices.read().await;
        devices_guard.get(device_id).cloned()
    }

    /// List all registered devices.
    pub async fn list_devices(&self) -> Vec<Device> {
        let devices_guard = self.devices.read().await;
        devices_guard.values().cloned().collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_device_registration_and_authentication_flow() {
        let identity_service = IdentityService::new();

        let req = RegistrationRequest {
            hostname: "dell-latitude-7480".into(),
            os_name: "Linux Ubuntu 24.04".into(),
            public_key_hex: "0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20"
                .into(),
        };

        let resp = identity_service.register_device(req.clone()).await;
        assert!(resp.success);
        assert!(resp.device_id.starts_with("rap-dev-"));
        assert!(resp.auth_token.starts_with("rap-token-"));

        // Verify authentication lookup using valid token
        let authenticated_device = identity_service.authenticate(&resp.auth_token).await;
        assert!(authenticated_device.is_some());
        let dev = authenticated_device.unwrap();
        assert_eq!(dev.hostname, req.hostname);
        assert!(dev.is_online);

        // Verify authentication fails for invalid token
        let invalid_auth = identity_service.authenticate("invalid-token").await;
        assert!(invalid_auth.is_none());

        // Test presence status update
        let updated = identity_service.set_presence(&resp.device_id, false).await;
        assert!(updated);
        let dev_after = identity_service.get_device(&resp.device_id).await.unwrap();
        assert!(!dev_after.is_online);
    }
}
