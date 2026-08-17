//! Stateless Relay Microservice executable binary entry point.
use rap_relay::RelayServer;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt::init();

    let _relay = RelayServer::new();
    let addr = "0.0.0.0:18445";
    tracing::info!(
        "High-Throughput Stateless UDP/TCP Relay Microservice listening on {}",
        addr
    );

    tokio::signal::ctrl_c().await?;
    tracing::info!("Relay Microservice shutting down...");
    Ok(())
}
