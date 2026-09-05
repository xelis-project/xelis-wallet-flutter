use std::sync::{Arc, Mutex};

use indexmap::{IndexMap, IndexSet};
use serde_json::json;
use xelis_common::rpc::RpcRequest;
use xelis_common::tokio::sync::{mpsc, oneshot};

use super::*;

fn app_state() -> Arc<AppState> {
    app_state_with_id("app-id")
}

fn app_state_with_id(id: &str) -> Arc<AppState> {
    let data: ApplicationData = serde_json::from_value(json!({
        "id": id,
        "name": "Test app",
        "description": "Test description",
        "url": "https://example.com",
        "permissions": ["get_balance", "build_transaction"]
    }))
    .unwrap();

    Arc::new(AppState::new(data))
}

fn prefetch_permissions() -> XSWDPrefetchPermissions {
    XSWDPrefetchPermissions {
        reason: Some("Prepare account view".to_owned()),
        permissions: IndexSet::from_iter(["get_balance".to_owned(), "get_assets".to_owned()]),
    }
}

fn prepared_disconnect(state: Arc<AppState>) -> PreparedXswdNotification {
    let application_info = AppInfo {
        session_ref: 1,
        id: state.get_id().to_string(),
        name: state.get_name().clone(),
        description: state.get_description().clone(),
        url: state.get_url().clone(),
        permissions: HashMap::new(),
        is_relayer: false,
    };
    PreparedXswdNotification {
        state,
        summary: XswdRequestSummary::new(XswdRequestType::AppDisconnect, application_info),
        kind: XswdNotificationKind::AppDisconnect,
        cancelled_application_admission: false,
    }
}

mod application;
mod lifecycle;
mod permissions;
mod projection;
