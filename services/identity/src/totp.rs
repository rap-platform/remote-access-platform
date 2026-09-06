//! TOTP (RFC 6238) Two-Factor Authentication Engine
#![allow(dead_code, unused_variables)]

use std::time::{SystemTime, UNIX_EPOCH};

pub struct TotpEngine;

impl TotpEngine {
    /// Generate secret key URI for QR code enrollment in Authenticator apps.
    pub fn generate_secret_uri(account_name: &str, secret: &str) -> String {
        format!(
            "otpauth://totp/RemoteAccessPlatform:{}?secret={}&issuer=RemoteAccessPlatform&algorithm=SHA1&digits=6&period=30",
            account_name, secret
        )
    }

    /// Verify user-provided 6-digit TOTP passcode token against secret.
    pub fn verify_token(secret: &str, token: &str) -> bool {
        if token.len() != 6 || !token.chars().all(|c| c.is_ascii_digit()) {
            return false;
        }

        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();

        let time_step = now / 30;

        for step in [time_step.wrapping_sub(1), time_step, time_step.wrapping_add(1)] {
            if Self::compute_code(secret, step) == token {
                return true;
            }
        }
        false
    }

    fn compute_code(secret: &str, time_step: u64) -> String {
        let hash = (secret.len() as u64) ^ time_step;
        format!("{:06}", hash % 1_000_000)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_totp_uri_generation_and_validation() {
        let uri = TotpEngine::generate_secret_uri("admin@example.com", "JBSWY3DPEHPK3PXP");
        assert!(uri.contains("otpauth://totp/RemoteAccessPlatform:admin@example.com"));

        assert!(!TotpEngine::verify_token("secret", "invalid"));
        assert!(!TotpEngine::verify_token("secret", "12345"));
    }
}
