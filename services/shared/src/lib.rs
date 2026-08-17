//! `rap-shared`: Shared types, error definitions, and utility abstractions for Rust backend services.

#![forbid(unsafe_code)]

/// Baseline service health status descriptor.
#[derive(Debug, Clone, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
pub enum HealthStatus {
    Healthy,
    Degraded,
    Unhealthy,
}

/// Baseline shared error type.
#[derive(Debug, thiserror::Error)]
pub enum SharedError {
    #[error("Internal service error: {0}")]
    Internal(String),
    #[error("Invalid request input: {0}")]
    InvalidInput(String),
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_health_status_serialization() {
        let status = HealthStatus::Healthy;
        let json = serde_json::to_string(&status).expect("Serialization failed");
        assert_eq!(json, "\"Healthy\"");

        let deserialized: HealthStatus =
            serde_json::from_str(&json).expect("Deserialization failed");
        assert_eq!(deserialized, HealthStatus::Healthy);
    }
}
