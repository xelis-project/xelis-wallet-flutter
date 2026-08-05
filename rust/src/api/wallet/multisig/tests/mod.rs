use std::{cell::Cell, future::ready};

use futures::executor::block_on;
use xelis_common::{
    api::{daemon::MultisigState, DataElement, DataValue},
    crypto::{Address, AddressType, Hash, KeyPair, Signature},
    serializer::Serializer,
};

use super::test_support::{
    configuration as multisig_configuration, signature as multisig_signature,
};
use super::{
    build_verified_multisig, create_authorized_multisig_signature_share,
    is_multisig_participant_address_valid, parse_multisig_participants,
    resolve_active_multisig_configuration, resolve_multisig_signing_configuration_with,
    verify_multisig_signature, PendingMultisigStore,
};

mod configuration;
mod participants;
mod pending;
mod signing;
