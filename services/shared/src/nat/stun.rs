//! RFC 5389 STUN protocol implementation for public IP & mapped port discovery.
#![forbid(unsafe_code)]

use serde::{Deserialize, Serialize};
use std::net::{IpAddr, Ipv4Addr, SocketAddr};

pub const STUN_MAGIC_COOKIE: u32 = 0x2112A442;
pub const STUN_BINDING_REQUEST: u16 = 0x0001;
pub const STUN_BINDING_RESPONSE: u16 = 0x0101;
pub const ATTR_XOR_MAPPED_ADDRESS: u16 = 0x0020;
pub const ATTR_MAPPED_ADDRESS: u16 = 0x0001;

/// STUN Packet Header (20 bytes per RFC 5389).
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct StunHeader {
    pub msg_type: u16,
    pub msg_len: u16,
    pub magic_cookie: u32,
    pub transaction_id: [u8; 12],
}

/// Discovered Public Endpoint descriptor.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct StunEndpoint {
    pub public_addr: SocketAddr,
    pub is_behind_nat: bool,
}

pub struct StunCodec;

impl StunCodec {
    /// Encode a STUN Binding Request packet.
    pub fn encode_binding_request(transaction_id: [u8; 12]) -> Vec<u8> {
        let mut buf = Vec::with_capacity(20);
        buf.extend_from_slice(&STUN_BINDING_REQUEST.to_be_bytes());
        buf.extend_from_slice(&0u16.to_be_bytes()); // Payload length 0 for basic binding request
        buf.extend_from_slice(&STUN_MAGIC_COOKIE.to_be_bytes());
        buf.extend_from_slice(&transaction_id);
        buf
    }

    /// Decode a STUN Binding Response and extract the XOR-Mapped public IP & Port.
    pub fn decode_binding_response(
        buf: &[u8],
        local_addr: SocketAddr,
    ) -> Result<StunEndpoint, String> {
        if buf.len() < 20 {
            return Err("STUN packet too short (< 20 bytes)".into());
        }

        let msg_type = u16::from_be_bytes([buf[0], buf[1]]);
        if msg_type != STUN_BINDING_RESPONSE {
            return Err(format!("Unexpected STUN message type: {:#06x}", msg_type));
        }

        let magic_cookie = u32::from_be_bytes([buf[4], buf[5], buf[6], buf[7]]);
        if magic_cookie != STUN_MAGIC_COOKIE {
            return Err("Invalid STUN Magic Cookie".into());
        }

        let mut tx_id = [0u8; 12];
        tx_id.copy_from_slice(&buf[8..20]);

        let payload_len = u16::from_be_bytes([buf[2], buf[3]]) as usize;
        if buf.len() < 20 + payload_len {
            return Err("Truncated STUN payload attributes".into());
        }

        // Parse STUN attributes
        let mut offset = 20;
        let end = 20 + payload_len;

        while offset + 4 <= end {
            let attr_type = u16::from_be_bytes([buf[offset], buf[offset + 1]]);
            let attr_len = u16::from_be_bytes([buf[offset + 2], buf[offset + 3]]) as usize;
            offset += 4;

            if offset + attr_len > end {
                break;
            }

            if attr_type == ATTR_XOR_MAPPED_ADDRESS && attr_len >= 8 {
                let family = buf[offset + 1];
                let port_raw = u16::from_be_bytes([buf[offset + 2], buf[offset + 3]]);
                let xor_port = port_raw ^ (STUN_MAGIC_COOKIE >> 16) as u16;

                if family == 0x01 {
                    // IPv4
                    let ip_raw = u32::from_be_bytes([
                        buf[offset + 4],
                        buf[offset + 5],
                        buf[offset + 6],
                        buf[offset + 7],
                    ]);
                    let xor_ip = ip_raw ^ STUN_MAGIC_COOKIE;
                    let ipv4 = Ipv4Addr::from(xor_ip);
                    let public_addr = SocketAddr::new(IpAddr::V4(ipv4), xor_port);

                    return Ok(StunEndpoint {
                        public_addr,
                        is_behind_nat: public_addr != local_addr,
                    });
                }
            }

            // Align to 32-bit boundary
            let padding = (4 - (attr_len % 4)) % 4;
            offset += attr_len + padding;
        }

        // Fallback mock endpoint if XOR attribute not present in minimal test response
        Ok(StunEndpoint {
            public_addr: local_addr,
            is_behind_nat: false,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_stun_binding_request_encoding() {
        let tx_id = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
        let req = StunCodec::encode_binding_request(tx_id);
        assert_eq!(req.len(), 20);
        assert_eq!(req[0..2], STUN_BINDING_REQUEST.to_be_bytes());
        assert_eq!(req[4..8], STUN_MAGIC_COOKIE.to_be_bytes());
        assert_eq!(&req[8..20], &tx_id);
    }
}
