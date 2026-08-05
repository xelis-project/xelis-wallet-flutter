//! Locks the private native DTO wire consumed by the generated FRB adapter.

use serde_json::json;
use xelis_wallet_flutter::api::models::wallet_dtos::{
    NativeMultisigParticipant, NativeMultisigSignatureShare, NativeMultisigSigningRequest,
    NativeMultisigSigningTransaction, NativeMultisigSigningTransfer,
};

#[test]
fn multisig_signing_request_round_trips_through_the_native_contract() {
    let request = NativeMultisigSigningRequest {
        request_id: None,
        encoded: "canonical-request".to_owned(),
        signing_hash: "11".repeat(32),
        source: "source-address".to_owned(),
        network: "testnet".to_owned(),
        fee: 1_000,
        fee_limit: 2_000,
        nonce: 7,
        reference_topoheight: 42,
        threshold: 2,
        participants: vec![
            NativeMultisigParticipant {
                id: 0,
                address: "participant-one".to_owned(),
            },
            NativeMultisigParticipant {
                id: 1,
                address: "participant-two".to_owned(),
            },
        ],
        signer_id: Some(1),
        transaction: NativeMultisigSigningTransaction::Transfers {
            transfers: vec![NativeMultisigSigningTransfer {
                amount: 125_000_000,
                asset: "22".repeat(32),
                destination: "destination-address".to_owned(),
                has_extra_data: true,
            }],
        },
    };

    let encoded = serde_json::to_value(&request).expect("public request should serialize");
    assert_eq!(encoded["signing_hash"], "11".repeat(32));
    assert!(encoded.get("hash").is_none());
    assert_eq!(
        encoded["transaction"],
        json!({
            "transfers": {
                "transfers": [{
                    "amount": 125_000_000,
                    "asset": "22".repeat(32),
                    "destination": "destination-address",
                    "has_extra_data": true
                }]
            }
        })
    );

    let decoded: NativeMultisigSigningRequest =
        serde_json::from_value(encoded).expect("public request should deserialize");
    assert_eq!(decoded.threshold, 2);
    assert_eq!(decoded.signer_id, Some(1));
    assert_eq!(decoded.participants.len(), 2);
    assert!(matches!(
        decoded.transaction,
        NativeMultisigSigningTransaction::Transfers { transfers }
            if transfers.len() == 1
                && transfers[0].amount == 125_000_000
                && transfers[0].has_extra_data
    ));
}

#[test]
fn multisig_signature_share_uses_the_public_signing_hash_contract() {
    let share = NativeMultisigSignatureShare {
        encoded: "canonical-signature-share".to_owned(),
        signing_hash: "33".repeat(32),
        signer_id: 2,
        signature: "44".repeat(64),
    };

    let encoded = serde_json::to_value(&share).expect("public share should serialize");

    assert_eq!(encoded["signing_hash"], "33".repeat(32));
    assert_eq!(encoded["signer_id"], 2);
    assert!(encoded.get("request_hash").is_none());

    let decoded: NativeMultisigSignatureShare =
        serde_json::from_value(encoded).expect("public share should deserialize");
    assert_eq!(decoded.signing_hash, "33".repeat(32));
    assert_eq!(decoded.signer_id, 2);
}

#[test]
fn multisig_transaction_variants_keep_their_public_serialization_tags() {
    let burn = serde_json::to_value(NativeMultisigSigningTransaction::Burn {
        asset: "asset".to_owned(),
        amount: 7,
    })
    .expect("burn transaction should serialize");
    let delete = serde_json::to_value(NativeMultisigSigningTransaction::DeleteMultisig)
        .expect("delete transaction should serialize");

    assert_eq!(burn, json!({"burn": {"asset": "asset", "amount": 7}}));
    assert_eq!(delete, json!("delete_multisig"));
}
