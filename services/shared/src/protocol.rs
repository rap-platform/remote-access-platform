//! Binary framing protocol codec implementation matching C++ `ProtocolCodec`.

use serde::{Deserialize, Serialize};

pub const MAGIC_HEADER: u32 = 0x52415030; // "RAP0"
pub const PROTOCOL_VERSION: u16 = 1;
pub const HEADER_SIZE: usize = 4 + 2 + 2 + 8 + 8 + 4; // 28 bytes

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[repr(u16)]
pub enum PayloadType {
    Unspecified = 0,
    HandshakeReq = 1,
    HandshakeResp = 2,
    FrameHeader = 3,
    InputEvent = 4,
    Heartbeat = 5,
    ClipboardData = 6,
    FileTransferRequest = 7,
    FileTransferResponse = 8,
    FileChunkPayload = 9,
    FileTransferControl = 10,
    DirectoryListRequest = 11,
    DirectoryListResponse = 12,
}

impl TryFrom<u16> for PayloadType {
    type Error = ProtocolError;

    fn try_from(val: u16) -> Result<Self, Self::Error> {
        match val {
            0 => Ok(PayloadType::Unspecified),
            1 => Ok(PayloadType::HandshakeReq),
            2 => Ok(PayloadType::HandshakeResp),
            3 => Ok(PayloadType::FrameHeader),
            4 => Ok(PayloadType::InputEvent),
            5 => Ok(PayloadType::Heartbeat),
            6 => Ok(PayloadType::ClipboardData),
            7 => Ok(PayloadType::FileTransferRequest),
            8 => Ok(PayloadType::FileTransferResponse),
            9 => Ok(PayloadType::FileChunkPayload),
            10 => Ok(PayloadType::FileTransferControl),
            11 => Ok(PayloadType::DirectoryListRequest),
            12 => Ok(PayloadType::DirectoryListResponse),
            _ => Err(ProtocolError::UnknownPayloadType(val)),
        }
    }
}

#[derive(Debug, thiserror::Error, PartialEq, Eq)]
pub enum ProtocolError {
    #[error("Incomplete header: data size smaller than 28 bytes")]
    IncompleteHeader,
    #[error("Invalid magic header: expected 0x52415030")]
    InvalidMagicHeader,
    #[error("Unsupported protocol version: {0}")]
    UnsupportedVersion(u16),
    #[error("Unknown payload type: {0}")]
    UnknownPayloadType(u16),
    #[error("Incomplete payload body")]
    IncompletePayload,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PacketHeader {
    pub magic: u32,
    pub version: u16,
    pub payload_type: PayloadType,
    pub sequence_number: u64,
    pub timestamp_ms: u64,
    pub payload_size: u32,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Packet {
    pub header: PacketHeader,
    pub payload: Vec<u8>,
}

impl Packet {
    pub fn encode(
        payload_type: PayloadType,
        sequence_number: u64,
        timestamp_ms: u64,
        payload: &[u8],
    ) -> Vec<u8> {
        let payload_size = payload.len() as u32;
        let mut buf = Vec::with_capacity(HEADER_SIZE + payload.len());

        buf.extend_from_slice(&MAGIC_HEADER.to_ne_bytes());
        buf.extend_from_slice(&PROTOCOL_VERSION.to_ne_bytes());
        buf.extend_from_slice(&(payload_type as u16).to_ne_bytes());
        buf.extend_from_slice(&sequence_number.to_ne_bytes());
        buf.extend_from_slice(&timestamp_ms.to_ne_bytes());
        buf.extend_from_slice(&payload_size.to_ne_bytes());
        buf.extend_from_slice(payload);

        buf
    }

    pub fn decode(data: &[u8]) -> Result<Self, ProtocolError> {
        if data.len() < HEADER_SIZE {
            return Err(ProtocolError::IncompleteHeader);
        }

        let magic_bytes: [u8; 4] = data[0..4]
            .try_into()
            .map_err(|_| ProtocolError::IncompleteHeader)?;
        let magic = u32::from_ne_bytes(magic_bytes);
        if magic != MAGIC_HEADER {
            return Err(ProtocolError::InvalidMagicHeader);
        }

        let ver_bytes: [u8; 2] = data[4..6]
            .try_into()
            .map_err(|_| ProtocolError::IncompleteHeader)?;
        let version = u16::from_ne_bytes(ver_bytes);
        if version != PROTOCOL_VERSION {
            return Err(ProtocolError::UnsupportedVersion(version));
        }

        let type_bytes: [u8; 2] = data[6..8]
            .try_into()
            .map_err(|_| ProtocolError::IncompleteHeader)?;
        let type_val = u16::from_ne_bytes(type_bytes);
        let payload_type = PayloadType::try_from(type_val)?;

        let seq_bytes: [u8; 8] = data[8..16]
            .try_into()
            .map_err(|_| ProtocolError::IncompleteHeader)?;
        let sequence_number = u64::from_ne_bytes(seq_bytes);

        let ts_bytes: [u8; 8] = data[16..24]
            .try_into()
            .map_err(|_| ProtocolError::IncompleteHeader)?;
        let timestamp_ms = u64::from_ne_bytes(ts_bytes);

        let size_bytes: [u8; 4] = data[24..28]
            .try_into()
            .map_err(|_| ProtocolError::IncompleteHeader)?;
        let payload_size = u32::from_ne_bytes(size_bytes);

        if data.len() < HEADER_SIZE + payload_size as usize {
            return Err(ProtocolError::IncompletePayload);
        }

        let payload = data[HEADER_SIZE..HEADER_SIZE + payload_size as usize].to_vec();

        Ok(Packet {
            header: PacketHeader {
                magic,
                version,
                payload_type,
                sequence_number,
                timestamp_ms,
                payload_size,
            },
            payload,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rust_protocol_encode_decode_roundtrip() {
        let payload = vec![0x10, 0x20, 0x30, 0x40];
        let seq = 42;
        let ts = 1000000;

        let encoded = Packet::encode(PayloadType::FrameHeader, seq, ts, &payload);
        assert_eq!(encoded.len(), HEADER_SIZE + 4);

        let decoded = Packet::decode(&encoded).expect("Decode failed");
        assert_eq!(decoded.header.magic, MAGIC_HEADER);
        assert_eq!(decoded.header.version, PROTOCOL_VERSION);
        assert_eq!(decoded.header.payload_type, PayloadType::FrameHeader);
        assert_eq!(decoded.header.sequence_number, seq);
        assert_eq!(decoded.header.timestamp_ms, ts);
        assert_eq!(decoded.header.payload_size, 4);
        assert_eq!(decoded.payload, payload);
    }
}
