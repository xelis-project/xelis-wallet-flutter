use super::*;
use crate::api::models::address_dtos::NativeXelisDataElement;

#[test]
fn maps_balance_and_asset_tracking_events_losslessly() {
    let hash = Hash::new([7; 32]);
    let balance = business_event_from_wallet_event(Event::BalanceChanged(BalanceChanged {
        asset: hash.clone(),
        balance: u64::MAX,
    }))
    .unwrap()
    .unwrap();
    match balance {
        NativeWalletBusinessEvent::BalanceChanged { asset, balance } => {
            assert_eq!(asset, hash.to_hex());
            assert_eq!(balance, u64::MAX);
        }
        _ => panic!("unexpected event"),
    }

    assert!(matches!(
        business_event_from_wallet_event(Event::TrackAsset { asset: hash.clone() }).unwrap(),
        Some(NativeWalletBusinessEvent::AssetTracked { asset }) if asset == hash.to_hex()
    ));
    assert!(matches!(
        business_event_from_wallet_event(Event::UntrackAsset { asset: hash.clone() }).unwrap(),
        Some(NativeWalletBusinessEvent::AssetUntracked { asset }) if asset == hash.to_hex()
    ));
}

#[test]
fn maps_transactions_pending_and_assets_losslessly() {
    let hash = Hash::new([9; 32]);
    let confirmed = business_event_from_wallet_event(Event::NewTransaction(TransactionEntry {
        hash: Cow::Owned(hash.clone()),
        topoheight: u64::MAX,
        timestamp: u64::MAX,
        entry: EntryType::Coinbase { reward: u64::MAX },
    }))
    .unwrap()
    .unwrap();
    match confirmed {
        NativeWalletBusinessEvent::NewTransaction { transaction } => {
            assert_eq!(transaction.hash, hash.to_hex());
            assert_eq!(transaction.topoheight, u64::MAX);
            assert_eq!(transaction.timestamp_millis, u64::MAX);
            assert!(matches!(
                transaction.entry,
                NativeWalletTransactionEntryData::Coinbase { reward: u64::MAX }
            ));
        }
        _ => panic!("unexpected event"),
    }

    let pending =
        business_event_from_wallet_event(Event::NewPendingTransaction(TransactionPending {
            hash: Cow::Owned(hash.clone()),
            timestamp: u64::MAX,
            entry: EntryType::Burn {
                asset: Cow::Owned(hash.clone()),
                amount: u64::MAX,
                fee: u64::MAX,
                nonce: u64::MAX,
            },
        }))
        .unwrap()
        .unwrap();
    match pending {
        NativeWalletBusinessEvent::NewPendingTransaction { transaction } => {
            assert_eq!(transaction.timestamp_millis, u64::MAX);
            assert!(matches!(
                transaction.entry,
                NativeWalletTransactionEntryData::Burn {
                    amount: u64::MAX,
                    fee: u64::MAX,
                    nonce: u64::MAX,
                    ..
                }
            ));
        }
        _ => panic!("unexpected event"),
    }

    let asset = business_event_from_wallet_event(Event::NewAsset(RPCAssetData {
        asset: Cow::Owned(hash.clone()),
        topoheight: u64::MAX,
        inner: AssetData::new(
            u8::MAX,
            "Maximum asset".to_owned(),
            "MAX".to_owned(),
            MaxSupplyMode::Mintable(u64::MAX),
            AssetOwner::Creator {
                contract: hash.clone(),
                id: u64::MAX,
            },
        ),
    }))
    .unwrap()
    .unwrap();
    match asset {
        NativeWalletBusinessEvent::NewAsset { asset } => {
            assert_eq!(asset.topoheight, u64::MAX);
            assert!(matches!(
                asset.metadata.max_supply,
                XelisMaxSupplyMode::Mintable(u64::MAX)
            ));
            assert!(matches!(
                asset.metadata.owner,
                XelisAssetOwner::Creator { id: u64::MAX, .. }
            ));
        }
        _ => panic!("unexpected event"),
    }
}

#[test]
fn maps_all_ten_transaction_variants_and_redacts_extra_data() {
    let hash = Hash::new([3; 32]);
    let address = KeyPair::new().get_public_key().to_address(false);
    let plaintext = PlaintextExtraData::new(
        Some(SharedKey([0xab; 32])),
        Some(DataElement::Value(DataValue::String(
            "private application payload".to_owned(),
        ))),
        PlaintextFlag::Private,
    );
    let mut amounts = IndexMap::new();
    amounts.insert(hash.clone(), u64::MAX);
    let mut grouped = IndexMap::new();
    grouped.insert(hash.clone(), amounts.clone());
    let mut destinations = IndexSet::new();
    destinations.insert(address.clone());

    let variants = vec![
        EntryType::Coinbase { reward: u64::MAX },
        EntryType::Burn {
            asset: Cow::Owned(hash.clone()),
            amount: u64::MAX,
            fee: u64::MAX,
            nonce: u64::MAX,
        },
        EntryType::Incoming {
            from: Cow::Owned(address.clone()),
            transfers: vec![TransferIn {
                asset: Cow::Owned(hash.clone()),
                amount: u64::MAX,
                extra_data: Cow::Owned(Some(plaintext.clone())),
            }],
        },
        EntryType::Outgoing {
            transfers: vec![TransferOut {
                destination: Cow::Owned(address.clone()),
                asset: Cow::Owned(hash.clone()),
                amount: u64::MAX,
                extra_data: Cow::Owned(Some(plaintext.clone())),
            }],
            fee: u64::MAX,
            nonce: u64::MAX,
        },
        EntryType::MultiSig {
            participants: Cow::Owned(vec![address.clone()]),
            threshold: u8::MAX,
            fee: u64::MAX,
            nonce: u64::MAX,
        },
        EntryType::InvokeContract {
            contract: Cow::Owned(hash.clone()),
            deposits: Cow::Owned(amounts.clone()),
            received: Cow::Owned(grouped.clone()),
            chunk_id: u16::MAX,
            fee: u64::MAX,
            max_gas: u64::MAX,
            nonce: u64::MAX,
        },
        EntryType::DeployContract {
            fee: u64::MAX,
            nonce: u64::MAX,
            invoke: Some(Cow::Owned(DeployInvoke {
                max_gas: u64::MAX,
                deposits: amounts.clone(),
            })),
        },
        EntryType::IncomingContract {
            transfers: Cow::Owned(grouped),
        },
        EntryType::OutgoingBlob {
            destinations: Cow::Owned(destinations.clone()),
            fee: u64::MAX,
            nonce: u64::MAX,
            data: Cow::Owned(plaintext.clone()),
        },
        EntryType::IncomingBlob {
            from: Cow::Owned(address),
            destinations: Cow::Owned(destinations),
            data: Cow::Owned(plaintext.clone()),
        },
    ];

    let mapped = variants
        .into_iter()
        .map(|value| transaction_entry_data(value, ExtraDataProjection::Redacted).unwrap())
        .collect::<Vec<_>>();
    assert!(matches!(
        mapped[0],
        NativeWalletTransactionEntryData::Coinbase { .. }
    ));
    assert!(matches!(
        mapped[1],
        NativeWalletTransactionEntryData::Burn { .. }
    ));
    assert!(matches!(
        mapped[2],
        NativeWalletTransactionEntryData::Incoming { .. }
    ));
    assert!(matches!(
        mapped[3],
        NativeWalletTransactionEntryData::Outgoing { .. }
    ));
    assert!(matches!(
        mapped[4],
        NativeWalletTransactionEntryData::Multisig { .. }
    ));
    assert!(matches!(
        mapped[5],
        NativeWalletTransactionEntryData::InvokeContract { .. }
    ));
    assert!(matches!(
        mapped[6],
        NativeWalletTransactionEntryData::DeployContract { .. }
    ));
    assert!(matches!(
        mapped[7],
        NativeWalletTransactionEntryData::IncomingContract { .. }
    ));
    assert!(matches!(
        mapped[8],
        NativeWalletTransactionEntryData::OutgoingBlob { .. }
    ));
    assert!(matches!(
        mapped[9],
        NativeWalletTransactionEntryData::IncomingBlob { .. }
    ));

    let redacted = extra_data(&plaintext, ExtraDataProjection::Redacted).unwrap();
    assert_eq!(redacted.flag, NativeWalletExtraDataFlag::Private);
    assert!(redacted.has_payload);
    assert!(redacted.payload.is_none());
    assert!(redacted.payload_kind.is_none());
    let debug = format!("{redacted:?}");
    assert!(!debug.contains("abababab"));
    assert!(!debug.contains("private application payload"));
    assert!(!debug.contains("shared_key"));

    let detailed = extra_data(&plaintext, ExtraDataProjection::Detailed).unwrap();
    assert!(detailed.has_payload);
    assert_eq!(
        detailed.payload_kind,
        Some(NativeWalletExtraDataPayloadKind::String)
    );
    assert!(matches!(
        detailed.payload,
        Some(NativeXelisDataElement::Value {
            value: crate::api::models::address_dtos::NativeXelisDataValue::StringValue {
                ref value,
            }
        }) if value == "private application payload"
    ));
}
