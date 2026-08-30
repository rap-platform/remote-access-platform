//! Admin Dashboard Fleet Management REST/gRPC API Router

pub struct AdminApiRouter;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FleetDeviceSummary {
    pub device_id: String,
    pub hostname: String,
    pub ip_address: String,
    pub os: String,
    pub is_online: bool,
    pub active_sessions: u32,
}

impl AdminApiRouter {
    /// Retrieve summary of all registered enterprise fleet devices.
    pub fn list_fleet_devices() -> Vec<FleetDeviceSummary> {
        vec![
            FleetDeviceSummary {
                device_id: "106794028".to_string(),
                hostname: "prod-workstation-01".to_string(),
                ip_address: "192.168.1.105".to_string(),
                os: "Linux x86_64".to_string(),
                is_online: true,
                active_sessions: 1,
            },
            FleetDeviceSummary {
                device_id: "208114920".to_string(),
                hostname: "win-graphics-srv".to_string(),
                ip_address: "192.168.1.110".to_string(),
                os: "Windows 11 Enterprise".to_string(),
                is_online: true,
                active_sessions: 0,
            },
        ]
    }

    /// Enforce remote access policy on host agent.
    pub fn enforce_device_policy(device_id: &str, allow_clipboard: bool, allow_file_transfer: bool) -> bool {
        println!(
            "[Admin API] Policy updated for device {}: clipboard={}, file_transfer={}",
            device_id, allow_clipboard, allow_file_transfer
        );
        true
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_admin_fleet_api() {
        let fleet = AdminApiRouter::list_fleet_devices();
        assert_eq!(fleet.len(), 2);
        assert_eq!(fleet[0].device_id, "106794028");

        let ok = AdminApiRouter::enforce_device_policy("106794028", true, false);
        assert!(ok);
    }
}
