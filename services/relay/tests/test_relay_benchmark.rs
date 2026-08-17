//! High-throughput Relay Microservice Load Benchmark Test.

use rap_relay::RelayServer;
use std::net::{IpAddr, Ipv4Addr, SocketAddr};
use std::time::Instant;

#[tokio::test]
async fn test_relay_high_throughput_benchmark_100k_packets() {
    let relay = RelayServer::new();
    let session_id = "bench-sess-100k".to_string();

    let client_addr = SocketAddr::new(IpAddr::V4(Ipv4Addr::new(192, 168, 1, 15)), 48000);
    let agent_addr = SocketAddr::new(IpAddr::V4(Ipv4Addr::new(10, 0, 0, 88)), 18443);

    relay
        .register_peer(session_id.clone(), client_addr, false)
        .await;
    relay
        .register_peer(session_id.clone(), agent_addr, true)
        .await;

    // Simulated 1400 byte network payload (MTU size)
    let payload = vec![0xaa; 1400];
    constexpr_iterations(100_000, &relay, &session_id, client_addr, &payload).await;

    let metrics = relay.get_metrics().await;
    assert_eq!(metrics.total_packets_relayed, 100_000);
    assert_eq!(metrics.total_bytes_relayed, 100_000 * 1400);
}

async fn constexpr_iterations(
    count: usize,
    relay: &RelayServer,
    session_id: &str,
    client_addr: SocketAddr,
    payload: &[u8],
) {
    let start = Instant::now();
    for _ in 0..count {
        let dest = relay.route_packet(session_id, client_addr, payload).await;
        assert!(dest.is_some());
    }
    let elapsed = start.elapsed();
    println!(
        "[Relay Load Benchmark] Relayed {} packets ({} MB) in {:?}. Throughput: {:.2} Kpkts/sec",
        count,
        (count * payload.len()) as f64 / 1_000_000.0,
        elapsed,
        (count as f64 / elapsed.as_secs_f64()) / 1000.0
    );
}
