# Security Policy & Vulnerability Disclosure

## 1. Safety & Disclosure Overview

Security is a foundational pillar of this platform. We welcome security research and public feedback on potential vulnerabilities.

To report a vulnerability, please email **security@remote-platform.local** (or submit a secure PGP-encrypted message using the key linked in repo release assets).

### Response SLA
- **Initial Acknowledgment**: Within 24 hours.
- **Triage & Severity Assessment**: Within 48 hours.
- **Remediation Release Target**: 
  - Critical / High (CVSS ≥ 7.0): Within 7 days.
  - Medium / Low (CVSS < 7.0): Within 30 days.

---

## 2. Security Guarantees & Non-Negotiables

1. **Zero Decryption Relay**: The data plane relay (`services/relay/`) is stateless and handles end-to-end encrypted packets (X25519 ECDH + XChaCha20-Poly1305 AEAD). Backend servers **never** hold or see session decryption keys.
2. **Device Identity Assurance**: Devices generate an Ed25519 keypair locally on first run; private keys never leave the host OS secure storage (TPM / Keyring / Secure Enclave).
3. **Rust Backend Safety**: All backend services are built strictly in Rust with `#![forbid(unsafe_code)]` at the crate root.
4. **Cleanroom IP Hygene**: Zero reverse-engineering or code copying from AnyDesk, RustDesk, or GPL/AGPL software.

---

## 3. Compliance Framework Mapping

- **OWASP ASVS v4/v5**: Target **Level 2** for client UI/agent; **Level 3** for identity, signaling, and crypto modules.
- **OWASP Top 10**: Enforced across API Gateway endpoints (`services/api-gateway/`).
- **NIST SSDF (SP 800-218)**: Secure Software Development Framework pipeline integration.
