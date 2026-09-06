//! Structured JSON logging initialization for Rust backend services matching the C++ log schema.

use serde::Serialize;
use tracing_subscriber::fmt::format::Writer;
use tracing_subscriber::fmt::FmtContext;
use tracing_subscriber::fmt::FormatEvent;
use tracing_subscriber::fmt::FormatFields;
use tracing_subscriber::registry::LookupSpan;

/// Standardized JSON log record matching the C++ `JsonLogger` schema.
#[derive(Debug, Clone, Serialize)]
pub struct JsonLogEntry<'a> {
    pub timestamp: String,
    pub level: &'static str,
    pub category: &'a str,
    pub file: Option<&'a str>,
    pub line: Option<u32>,
    pub message: String,
}

pub struct CustomJsonFormatter;

impl<S, N> FormatEvent<S, N> for CustomJsonFormatter
where
    S: tracing::Subscriber + for<'a> LookupSpan<'a>,
    N: for<'a> FormatFields<'a> + 'static,
{
    fn format_event(
        &self,
        ctx: &FmtContext<'_, S, N>,
        mut writer: Writer<'_>,
        event: &tracing::Event<'_>,
    ) -> std::fmt::Result {
        let meta = event.metadata();
        let timestamp = chrono::Utc::now().to_rfc3339_opts(chrono::SecondsFormat::Millis, true);

        let message = String::new();
        ctx.format_fields(writer.by_ref(), event)?;

        let level_str = match *meta.level() {
            tracing::Level::TRACE => "TRACE",
            tracing::Level::DEBUG => "DEBUG",
            tracing::Level::INFO => "INFO",
            tracing::Level::WARN => "WARNING",
            tracing::Level::ERROR => "CRITICAL",
        };

        let entry = JsonLogEntry {
            timestamp,
            level: level_str,
            category: meta.target(),
            file: meta.file(),
            line: meta.line(),
            message,
        };

        if let Ok(json) = serde_json::to_string(&entry) {
            writeln!(writer, "{}", json)?;
        }
        Ok(())
    }
}

/// Initialize tracing subscriber with default JSON output.
pub fn init_json_logging(service_name: &str) {
    let subscriber = tracing_subscriber::fmt()
        .json()
        .with_env_filter(
            tracing_subscriber::EnvFilter::from_default_env()
                .add_directive(tracing::Level::INFO.into()),
        )
        .finish();

    let _ = tracing::subscriber::set_global_default(subscriber);
    tracing::info!(
        service = service_name,
        "Structured JSON logging initialized"
    );
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_json_log_entry_serialization() {
        let entry = JsonLogEntry {
            timestamp: "2026-08-17T12:00:00.000Z".to_string(),
            level: "INFO",
            category: "rap_signaling",
            file: Some("src/main.rs"),
            line: Some(42),
            message: "Test signaling event".to_string(),
        };

        let json = serde_json::to_string(&entry).expect("Serialization failed");
        assert!(json.contains("\"level\":\"INFO\""));
        assert!(json.contains("\"category\":\"rap_signaling\""));
        assert!(json.contains("\"line\":42"));
    }
}
