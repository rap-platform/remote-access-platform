//! Rendezvous & Signaling Service executable binary entry point.
use rap_signaling::SignalingServer;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt::init();

    let _server = SignalingServer::new();
    let addr = "0.0.0.0:8082";
    tracing::info!("Rendezvous & Signaling Microservice starting on {}", addr);

    tokio::signal::ctrl_c().await?;
    tracing::info!("Rendezvous & Signaling Microservice shutting down...");
    Ok(())
}
