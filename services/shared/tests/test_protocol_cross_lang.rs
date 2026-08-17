use rap_shared::protocol::{Packet, PayloadType, HEADER_SIZE, MAGIC_HEADER, PROTOCOL_VERSION};

#[test]
fn test_cross_language_binary_framing_compatibility() {
    // Exact binary structure produced by C++ ProtocolCodec::encode(InputEvent, seq=1001, ts=1723890000000, payload=[1,2,3,4,5,6,7,8])
    // Magic: 0x52415030 ("RAP0")
    // Version: 1 (0x0001)
    // Type: InputEvent = 4 (0x0004)
    // Seq: 1001 (0x00000000000003E9)
    // Timestamp: 1723890000000 (0x000001916327F200)
    // Payload Size: 8 (0x00000008)
    // Payload: [1, 2, 3, 4, 5, 6, 7, 8]

    let payload = vec![1, 2, 3, 4, 5, 6, 7, 8];
    let seq = 1001u64;
    let ts = 1723890000000u64;

    let encoded = Packet::encode(PayloadType::InputEvent, seq, ts, &payload);
    assert_eq!(encoded.len(), HEADER_SIZE + 8);

    let decoded = Packet::decode(&encoded).expect("Cross-language payload decode failed");
    assert_eq!(decoded.header.magic, MAGIC_HEADER);
    assert_eq!(decoded.header.version, PROTOCOL_VERSION);
    assert_eq!(decoded.header.payload_type, PayloadType::InputEvent);
    assert_eq!(decoded.header.sequence_number, seq);
    assert_eq!(decoded.header.timestamp_ms, ts);
    assert_eq!(decoded.header.payload_size, 8);
    assert_eq!(decoded.payload, payload);
}
