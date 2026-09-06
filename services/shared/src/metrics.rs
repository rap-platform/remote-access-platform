//! Prometheus Metrics Exporter & Observability Registry
#![allow(dead_code, unused_variables)]

use std::sync::atomic::{AtomicU64, Ordering};

pub struct ServiceMetrics {
    pub active_sessions: AtomicU64,
    pub total_bytes_relayed: AtomicU64,
    pub total_handshakes: AtomicU64,
}

impl ServiceMetrics {
    pub const fn new() -> Self {
        Self {
            active_sessions: AtomicU64::new(0),
            total_bytes_relayed: AtomicU64::new(0),
            total_handshakes: AtomicU64::new(0),
        }
    }

    pub fn record_handshake(&self) {
        self.total_handshakes.fetch_add(1, Ordering::Relaxed);
    }

    pub fn record_bytes(&self, bytes: u64) {
        self.total_bytes_relayed.fetch_add(bytes, Ordering::Relaxed);
    }

    pub fn export_prometheus_format(&self) -> String {
        format!(
            "# HELP rap_relay_active_sessions Active remote sessions count\n\
             # TYPE rap_relay_active_sessions gauge\n\
             rap_relay_active_sessions {}\n\n\
             # HELP rap_relay_bytes_relayed_total Total bytes forwarded by relay\n\
             # TYPE rap_relay_bytes_relayed_total counter\n\
             rap_relay_bytes_relayed_total {}\n\n\
             # HELP rap_signaling_handshakes_total Total P2P handshakes established\n\
             # TYPE rap_signaling_handshakes_total counter\n\
             rap_signaling_handshakes_total {}\n",
            self.active_sessions.load(Ordering::Relaxed),
            self.total_bytes_relayed.load(Ordering::Relaxed),
            self.total_handshakes.load(Ordering::Relaxed)
        )
    }
}

pub static METRICS: ServiceMetrics = ServiceMetrics::new();

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_metrics_collection_and_prometheus_export() {
        let metrics = ServiceMetrics::new();
        metrics.record_handshake();
        metrics.record_bytes(1024);
        let output = metrics.export_prometheus_format();
        assert!(output.contains("rap_relay_bytes_relayed_total 1024"));
        assert!(output.contains("rap_signaling_handshakes_total 1"));
    }
}
