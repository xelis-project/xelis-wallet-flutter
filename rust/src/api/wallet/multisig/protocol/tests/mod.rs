use xelis_common::{
    config::{COIN_VALUE, XELIS_ASSET},
    crypto::{proofs::BalanceProof, Hash, KeyPair},
    network::Network,
    serializer::Serializer,
};

use super::{
    build_verified_multisig, create_multisig_signature_share, create_multisig_signing_request,
    multisig_request_signing_bytes, parse_multisig_signature_share, parse_multisig_signing_request,
    validate_multisig_setup, verify_multisig_signature, MultisigSignatureShareEnvelope,
    MultisigSigningRequestEnvelope, MultisigSigningRequestPayload,
    MultisigSigningRequestTransaction, MAX_MULTISIG_SIGNATURE_SHARE_SIZE,
    MAX_MULTISIG_SIGNING_REQUEST_SIZE, MULTISIG_SIGNATURE_SHARE_VERSION,
    MULTISIG_SIGNING_REQUEST_DOMAIN, MULTISIG_SIGNING_REQUEST_VERSION,
};
use crate::api::models::wallet_dtos::NativeMultisigSigningTransaction;

mod protocol;
mod signature_share;
mod signing_request;

use super::super::test_support::{
    burn_request_fixture, configuration, signature, transfer_request_fixture,
};
