//! API Gateway executable binary entry point.
use rap_api_gateway::{create_router, AppState};
use rap_identity::IdentityService;
use rap_signaling::SignalingServer;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt::init();

    let state = AppState {
        identity: IdentityService::new(),
        signaling: SignalingServer::new(),
    };

    let app = create_router(state);
    let addr = "0.0.0.0:8080";
    tracing::info!(
        "Starting Remote Access Platform API Gateway on http://{}",
        addr
    );

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
