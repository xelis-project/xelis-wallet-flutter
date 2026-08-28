use std::sync::{Arc, Mutex};

use indexmap::{IndexMap, IndexSet};
use serde_json::json;
use xelis_common::rpc::RpcRequest;
use xelis_common::tokio::sync::{mpsc, oneshot};

use super::*;

fn app_state() -> Arc<AppState> {
    let data: ApplicationData = serde_json::from_value(json!({
        "id": "app-id",
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

mod application;
mod lifecycle;
mod permissions;
mod projection;
