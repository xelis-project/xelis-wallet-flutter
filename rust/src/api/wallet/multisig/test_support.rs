use indexmap::IndexSet;
use xelis_common::{
    config::{COIN_VALUE, XELIS_ASSET},
    crypto::{Hash, KeyPair},
    serializer::Serializer,
    transaction::{
        builder::{FeeBuilder, TransactionBuilder, TransactionTypeBuilder, TransferBuilder},
        mock::{TrackedAccount, TrackedAccountState},
        BurnPayload, MultiSigPayload, Reference, TxVersion,
    },
};

use super::protocol::MultisigSignature;

pub(super) fn signature(id: u8, keypair: &KeyPair, hash: &Hash) -> MultisigSignature {
    MultisigSignature {
        id,
        signature: keypair.sign(hash.as_bytes()).to_hex(),
    }
}

pub(super) fn configuration(keypairs: &[&KeyPair], threshold: u8) -> MultiSigPayload {
    MultiSigPayload {
        threshold,
        participants: keypairs
            .iter()
            .map(|keypair| keypair.get_public_key().compress())
            .collect::<IndexSet<_>>(),
    }
}

pub(super) fn burn_request_fixture() -> (
    TrackedAccount,
    xelis_common::transaction::builder::UnsignedTransaction,
    TransactionTypeBuilder,
    MultiSigPayload,
) {
    let mut source = TrackedAccount::new();
    source.set_balance(XELIS_ASSET, 100 * COIN_VALUE);
    let mut state = TrackedAccountState {
        balances: source.balances.clone(),
        reference: Reference {
            hash: Hash::zero(),
            topoheight: 42,
        },
        nonce: source.nonce,
    };
    let transaction_type = TransactionTypeBuilder::Burn(BurnPayload {
        asset: XELIS_ASSET,
        amount: 10 * COIN_VALUE,
    });
    let builder = TransactionBuilder::new(
        TxVersion::V1,
        source.get_public_key(),
        Some(1),
        transaction_type.clone(),
        FeeBuilder::default(),
    );
    let unsigned = builder.build_unsigned(&mut state, &source.keypair).unwrap();
    let signer = KeyPair::new();
    let configuration = configuration(&[&signer], 1);

    (source, unsigned, transaction_type, configuration)
}

pub(super) fn transfer_request_fixture() -> (
    TrackedAccount,
    xelis_common::transaction::builder::UnsignedTransaction,
    TransactionTypeBuilder,
    MultiSigPayload,
) {
    let mut source = TrackedAccount::new();
    source.set_balance(XELIS_ASSET, 100 * COIN_VALUE);
    let first_destination = TrackedAccount::new();
    let second_destination = TrackedAccount::new();
    let mut state = TrackedAccountState {
        balances: source.balances.clone(),
        reference: Reference {
            hash: Hash::zero(),
            topoheight: 42,
        },
        nonce: source.nonce,
    };
    let transaction_type = TransactionTypeBuilder::Transfers(vec![
        TransferBuilder {
            asset: XELIS_ASSET,
            amount: 10 * COIN_VALUE,
            destination: first_destination.address(),
            extra_data: None,
            encrypt_extra_data: true,
        },
        TransferBuilder {
            asset: XELIS_ASSET,
            amount: 20 * COIN_VALUE,
            destination: second_destination.address(),
            extra_data: None,
            encrypt_extra_data: true,
        },
    ]);
    let builder = TransactionBuilder::new(
        TxVersion::V1,
        source.get_public_key(),
        Some(1),
        transaction_type.clone(),
        FeeBuilder::default(),
    );
    let unsigned = builder.build_unsigned(&mut state, &source.keypair).unwrap();
    let signer = KeyPair::new();
    let configuration = configuration(&[&signer], 1);

    (source, unsigned, transaction_type, configuration)
}
