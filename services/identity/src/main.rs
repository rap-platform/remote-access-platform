//! Device Identity Service executable binary entry point.
use rap_identity::IdentityService;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt::init();

    let _service = IdentityService::new();
    let addr = "0.0.0.0:8081";
    tracing::info!("Device Identity Microservice starting on {}", addr);

    tokio::signal::ctrl_c().await?;
    tracing::info!("Device Identity Microservice shutting down...");
    Ok(())
}
