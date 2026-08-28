use super::*;
use serde_json::json;

const MAX_XSWD_PAYLOAD_DEPTH: usize = DEFAULT_XSWD_PAYLOAD_DEPTH as usize;
const MAX_XSWD_PAYLOAD_TOKENS: usize = DEFAULT_XSWD_PAYLOAD_TOKENS as usize;
const MAX_XSWD_CONTAINER_MEMBERS: usize = DEFAULT_XSWD_CONTAINER_MEMBERS as usize;
const MAX_XSWD_TEXT_BYTES: usize = DEFAULT_XSWD_TEXT_BYTES as usize;
const MAX_XSWD_TOTAL_TEXT_BYTES: usize = DEFAULT_XSWD_TOTAL_TEXT_BYTES as usize;

fn app_info() -> AppInfo {
    AppInfo {
        id: "app-id".to_owned(),
        name: "Test app".to_owned(),
        description: "Test description".to_owned(),
        url: Some("https://example.com".to_owned()),
        permissions: HashMap::new(),
        is_relayer: false,
    }
}

#[test]
fn request_type_helpers_identify_each_event_exclusively() {
    let cases = [
        (
            XswdRequestType::Application,
            [false, true, false, false, false],
        ),
        (
            XswdRequestType::Permission(projected_payload(json!({
                "method": "get_balance"
            }))),
            [false, false, true, false, false],
        ),
        (
            XswdRequestType::PrefetchPermissions(projected_payload(json!({
                "permissions": ["get_balance"]
            }))),
            [false, false, false, true, false],
        ),
        (
            XswdRequestType::CancelRequest,
            [true, false, false, false, false],
        ),
        (
            XswdRequestType::AppDisconnect,
            [false, false, false, false, true],
        ),
    ];

    for (event_type, expected) in cases {
        let summary = XswdRequestSummary::new(event_type, app_info());
        assert_eq!(
            [
                summary.is_cancel_request(),
                summary.is_application_request(),
                summary.is_permission_request(),
                summary.is_prefetch_permissions_request(),
                summary.is_app_disconnect(),
            ],
            expected
        );
    }
}

#[test]
fn projection_preserves_json_value_types_and_exact_integer_text() {
    let payload = projected_payload(json!({
        "null": null,
        "bool": true,
        "string": "18446744073709551616",
        "negative": i64::MIN,
        "safe": 9_007_199_254_740_991_u64,
        "edge": 9_007_199_254_740_992_u64,
        "unsafeInJavascript": 9_007_199_254_740_993_u64,
        "maximum": u64::MAX,
        "float": 1.5,
        "list": [1, false]
    }));

    for expected in [
        "9007199254740993",
        "18446744073709551615",
        "-9223372036854775808",
    ] {
        assert!(payload.tokens.iter().any(|token| {
            matches!(token.kind, NativeXswdPayloadTokenKind::Integer)
                && token.text_value.as_deref() == Some(expected)
        }));
    }
    assert!(payload.tokens.iter().any(|token| {
        matches!(token.kind, NativeXswdPayloadTokenKind::StringValue)
            && token.text_value.as_deref() == Some("18446744073709551616")
    }));
    assert!(payload.tokens.iter().any(|token| {
        matches!(token.kind, NativeXswdPayloadTokenKind::Float) && token.float_value == Some(1.5)
    }));
}

#[test]
fn projection_debug_output_redacts_keys_values_and_signers() {
    let signer = "sentinel-private-key";
    let payload = projected_payload(json!({
        "signers": [{"id": 7, "private_key": signer}],
        "amount": u64::MAX
    }));

    let debug = format!("{payload:?}");
    assert!(!debug.contains(signer));
    assert!(!debug.contains("private_key"));
    assert!(!debug.contains("signers"));
    assert!(!debug.contains(&u64::MAX.to_string()));

    for token in &payload.tokens {
        let debug = format!("{token:?}");
        assert!(!debug.contains(signer));
        assert!(!debug.contains("private_key"));
        assert!(!debug.contains("signers"));
        assert!(!debug.contains(&u64::MAX.to_string()));
    }
}

#[test]
fn projection_rejects_non_object_roots() {
    assert_eq!(
        NativeXswdPayload::project(&vec![1_u8], NativeXswdProjectionLimits::default()).unwrap_err(),
        XswdPayloadProjectionError::RootNotObject
    );
}

#[test]
fn projection_limits_validate_defaults_custom_values_and_technical_ceilings() {
    assert!(NativeXswdProjectionLimits::default().validate().is_ok());
    assert!(NativeXswdProjectionLimits {
        max_depth: 128,
        max_tokens: 262_144,
        max_container_members: 65_536,
        max_text_bytes: 8 * 1024 * 1024,
        max_total_text_bytes: 16 * 1024 * 1024,
    }
    .validate()
    .is_ok());

    let invalid = [
        NativeXswdProjectionLimits {
            max_depth: 129,
            ..Default::default()
        },
        NativeXswdProjectionLimits {
            max_tokens: 262_145,
            ..Default::default()
        },
        NativeXswdProjectionLimits {
            max_container_members: 65_537,
            ..Default::default()
        },
        NativeXswdProjectionLimits {
            max_text_bytes: 8 * 1024 * 1024 + 1,
            max_total_text_bytes: 16 * 1024 * 1024,
            ..Default::default()
        },
        NativeXswdProjectionLimits {
            max_text_bytes: 1024,
            max_total_text_bytes: 1023,
            ..Default::default()
        },
    ];
    assert!(invalid.into_iter().all(|limits| limits.validate().is_err()));
}

#[test]
fn projection_enforces_depth_container_and_text_limits() {
    let oversized_array = vec![Value::Null; MAX_XSWD_CONTAINER_MEMBERS + 1];
    assert_eq!(
        NativeXswdPayload::project(
            &json!({"values": oversized_array}),
            NativeXswdProjectionLimits::default()
        )
        .unwrap_err(),
        XswdPayloadProjectionError::ContainerLimit
    );

    let mut nested = Value::Null;
    for _ in 0..MAX_XSWD_PAYLOAD_DEPTH {
        nested = Value::Array(vec![nested]);
    }
    assert_eq!(
        NativeXswdPayload::project(
            &json!({"value": nested}),
            NativeXswdProjectionLimits::default()
        )
        .unwrap_err(),
        XswdPayloadProjectionError::DepthLimit
    );

    let oversized_text = "x".repeat(MAX_XSWD_TEXT_BYTES + 1);
    assert_eq!(
        NativeXswdPayload::project(
            &json!({"value": oversized_text}),
            NativeXswdProjectionLimits::default()
        )
        .unwrap_err(),
        XswdPayloadProjectionError::TextLimit
    );

    let text = "x".repeat(3 * 1024 * 1024);
    assert_eq!(
        NativeXswdPayload::project(
            &json!({
                "first": text,
                "second": "y".repeat(3 * 1024 * 1024),
                "third": "z".repeat(3 * 1024 * 1024)
            }),
            NativeXswdProjectionLimits::default()
        )
        .unwrap_err(),
        XswdPayloadProjectionError::TotalTextLimit
    );
}

#[test]
fn projection_accepts_every_resource_limit_at_its_boundary() {
    let maximum_array = vec![Value::Null; MAX_XSWD_CONTAINER_MEMBERS];
    NativeXswdPayload::project(
        &json!({"values": maximum_array}),
        NativeXswdProjectionLimits::default(),
    )
    .unwrap();

    let maximum_text = "x".repeat(MAX_XSWD_TEXT_BYTES);
    NativeXswdPayload::project(
        &json!({"value": maximum_text}),
        NativeXswdProjectionLimits::default(),
    )
    .unwrap();

    let half_total_text = "x".repeat((MAX_XSWD_TOTAL_TEXT_BYTES / 2) - 1);
    NativeXswdPayload::project(
        &json!({
            "a": half_total_text,
            "b": "y".repeat((MAX_XSWD_TOTAL_TEXT_BYTES / 2) - 1)
        }),
        NativeXswdProjectionLimits::default(),
    )
    .unwrap();

    let mut maximum_depth = Value::Null;
    for _ in 0..62 {
        maximum_depth = Value::Array(vec![maximum_depth]);
    }
    NativeXswdPayload::project(
        &json!({"value": maximum_depth}),
        NativeXswdProjectionLimits::default(),
    )
    .unwrap();

    let mut exact_tokens = serde_json::Map::new();
    for index in 0..15 {
        exact_tokens.insert(
            format!("values_{index}"),
            Value::Array(vec![Value::Null; MAX_XSWD_CONTAINER_MEMBERS]),
        );
    }
    exact_tokens.insert(
        "values_15".to_owned(),
        Value::Array(vec![Value::Null; 4_063]),
    );
    let projection = NativeXswdPayload::project(
        &Value::Object(exact_tokens),
        NativeXswdProjectionLimits::default(),
    )
    .unwrap();
    assert_eq!(projection.tokens.len(), MAX_XSWD_PAYLOAD_TOKENS);
}

#[test]
fn projection_enforces_the_total_token_limit() {
    let arrays = (0..17)
        .map(|index| {
            (
                format!("values_{index}"),
                Value::Array(vec![Value::Null; MAX_XSWD_CONTAINER_MEMBERS]),
            )
        })
        .collect::<serde_json::Map<_, _>>();

    assert_eq!(
        NativeXswdPayload::project(
            &Value::Object(arrays),
            NativeXswdProjectionLimits::default()
        )
        .unwrap_err(),
        XswdPayloadProjectionError::TokenLimit
    );
}

fn projected_payload(value: Value) -> NativeXswdPayload {
    NativeXswdPayload::project(&value, NativeXswdProjectionLimits::default()).unwrap()
}
