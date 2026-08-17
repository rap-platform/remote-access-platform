//! API Gateway service crate providing Axum REST & WebSocket routes.
#![forbid(unsafe_code)]

use axum::{
    extract::{Query, State},
    http::StatusCode,
    routing::{get, post},
    Json, Router,
};
use rap_audit::{AuditEvent, AuditLogIntegrityReport, AuditLogService};
use rap_identity::{IdentityService, RegistrationRequest, RegistrationResponse};
use rap_signaling::{SignalingServer, SignalingSession};
use serde::{Deserialize, Serialize};
use std::sync::Arc;

#[derive(Clone)]
pub struct AppState {
    pub identity: IdentityService,
    pub signaling: SignalingServer,
    pub audit: AuditLogService,
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

#[derive(Debug, Deserialize)]
pub struct AuditQueryParams {
    pub event_type: Option<String>,
    pub actor: Option<String>,
    pub limit: Option<usize>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreateAuditLogRequest {
    pub event_type: String,
    pub actor: String,
    pub resource: String,
    pub status: String,
    pub details: String,
}

pub fn create_router(state: AppState) -> Router {
    Router::new()
        .route("/api/v1/health", get(health_handler))
        .route("/api/v1/identity/register", post(register_device_handler))
        .route("/api/v1/signaling/initiate", post(initiate_session_handler))
        .route("/api/v1/audit/logs", get(query_audit_logs_handler))
        .route("/api/v1/audit/verify", get(verify_audit_integrity_handler))
        .route("/api/v1/audit/log", post(create_audit_log_handler))
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
    let hostname = req.hostname.clone();
    let resp = state.identity.register_device(req).await;
    state
        .signaling
        .register_peer(resp.device_id.clone(), true)
        .await;

    state
        .audit
        .log_event(
            "DEVICE_REGISTER",
            hostname,
            resp.device_id.clone(),
            "SUCCESS",
            "Registered new remote desktop agent device",
        )
        .await;

    Json(resp)
}

async fn initiate_session_handler(
    State(state): State<Arc<AppState>>,
    Json(req): Json<InitiateSessionRequest>,
) -> Result<Json<SignalingSession>, (StatusCode, String)> {
    let client_id = req.client_device_id.clone();
    let target_id = req.target_agent_id.clone();

    match state
        .signaling
        .initiate_session(
            req.client_device_id,
            req.target_agent_id,
            req.client_public_key_hex,
        )
        .await
    {
        Ok(session) => {
            state
                .audit
                .log_event(
                    "SESSION_CONNECT",
                    client_id,
                    target_id,
                    "SUCCESS",
                    format!("Initiated session {}", session.session_id),
                )
                .await;
            Ok(Json(session))
        }
        Err(err) => {
            state
                .audit
                .log_event(
                    "SESSION_CONNECT",
                    client_id,
                    target_id,
                    "FAILED",
                    err.clone(),
                )
                .await;
            Err((StatusCode::BAD_REQUEST, err))
        }
    }
}

async fn query_audit_logs_handler(
    State(state): State<Arc<AppState>>,
    Query(params): Query<AuditQueryParams>,
) -> Json<Vec<AuditEvent>> {
    let logs = state
        .audit
        .query_logs(
            params.event_type.as_deref(),
            params.actor.as_deref(),
            params.limit.unwrap_or(100),
        )
        .await;
    Json(logs)
}

async fn verify_audit_integrity_handler(
    State(state): State<Arc<AppState>>,
) -> Json<AuditLogIntegrityReport> {
    let report = state.audit.verify_integrity().await;
    Json(report)
}

async fn create_audit_log_handler(
    State(state): State<Arc<AppState>>,
    Json(req): Json<CreateAuditLogRequest>,
) -> Json<AuditEvent> {
    let event = state
        .audit
        .log_event(
            req.event_type,
            req.actor,
            req.resource,
            req.status,
            req.details,
        )
        .await;
    Json(event)
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
    async fn test_api_gateway_registration_and_audit_integration() {
        let state = AppState {
            identity: IdentityService::new(),
            signaling: SignalingServer::new(),
            audit: AuditLogService::new(),
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

        let init_res =
            initiate_session_handler(State(Arc::new(state.clone())), Json(init_req)).await;
        assert!(init_res.is_ok());

        // Verify audit logs generated automatically
        let logs = state.audit.query_logs(None, None, 100).await;
        assert_eq!(logs.len(), 2);
        assert_eq!(logs[0].event_type, "DEVICE_REGISTER");
        assert_eq!(logs[1].event_type, "SESSION_CONNECT");

        // Verify cryptographic hash chain integrity
        let integrity = state.audit.verify_integrity().await;
        assert!(integrity.is_valid);
        assert_eq!(integrity.total_events, 2);
    }
}
