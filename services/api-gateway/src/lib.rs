//! API Gateway service crate providing Axum REST & WebSocket routes.
#![forbid(unsafe_code)]

use axum::{
    extract::State,
    http::StatusCode,
    routing::{get, post},
    Json, Router,
};
use rap_identity::{IdentityService, RegistrationRequest, RegistrationResponse};
use rap_signaling::{SignalingServer, SignalingSession};
use serde::{Deserialize, Serialize};
use std::sync::Arc;

#[derive(Clone)]
pub struct AppState {
    pub identity: IdentityService,
    pub signaling: SignalingServer,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct HealthResponse {
    pub status: String,
    pub service: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct InitiateSessionRequest {
    pub client_device_id: String,
    pub target_agent_id: String,
    pub client_public_key_hex: String,
}

pub fn create_router(state: AppState) -> Router {
    Router::new()
        .route("/api/v1/health", get(health_handler))
        .route("/api/v1/identity/register", post(register_device_handler))
        .route("/api/v1/signaling/initiate", post(initiate_session_handler))
        .with_state(Arc::new(state))
}

async fn health_handler() -> Json<HealthResponse> {
    Json(HealthResponse {
        status: "ok".into(),
        service: "rap-api-gateway".into(),
    })
}

async fn register_device_handler(
    State(state): State<Arc<AppState>>,
    Json(req): Json<RegistrationRequest>,
) -> Json<RegistrationResponse> {
    let resp = state.identity.register_device(req).await;
    state
        .signaling
        .register_peer(resp.device_id.clone(), true)
        .await;
    Json(resp)
}

async fn initiate_session_handler(
    State(state): State<Arc<AppState>>,
    Json(req): Json<InitiateSessionRequest>,
) -> Result<Json<SignalingSession>, (StatusCode, String)> {
    match state
        .signaling
        .initiate_session(
            req.client_device_id,
            req.target_agent_id,
            req.client_public_key_hex,
        )
        .await
    {
        Ok(session) => Ok(Json(session)),
        Err(err) => Err((StatusCode::BAD_REQUEST, err)),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_api_gateway_health_check() {
        let resp = health_handler().await;
        assert_eq!(resp.status, "ok");
        assert_eq!(resp.service, "rap-api-gateway");
    }

    #[tokio::test]
    async fn test_api_gateway_registration_and_session_initiation() {
        let state = AppState {
            identity: IdentityService::new(),
            signaling: SignalingServer::new(),
        };

        let reg_req = RegistrationRequest {
            hostname: "test-host".into(),
            os_name: "Linux".into(),
            public_key_hex: "01020304".into(),
        };

        let reg_resp = register_device_handler(State(Arc::new(state.clone())), Json(reg_req)).await;
        assert!(reg_resp.success);

        let init_req = InitiateSessionRequest {
            client_device_id: "client-001".into(),
            target_agent_id: reg_resp.device_id.clone(),
            client_public_key_hex: "abcd".into(),
        };

        let init_res = initiate_session_handler(State(Arc::new(state)), Json(init_req)).await;
        assert!(init_res.is_ok());
        if let Ok(Json(session)) = init_res {
            assert_eq!(session.agent_device_id, reg_resp.device_id);
        }
    }
}
