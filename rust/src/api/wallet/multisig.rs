use std::borrow::Cow;

#[cfg(test)]
use std::future::Future;

use self::protocol::{
    build_verified_multisig, create_multisig_signature_share, create_multisig_signing_request,
    parse_multisig_signature_share, parse_multisig_signing_request, validate_multisig_setup,
    verify_multisig_signature, ParsedMultisigSigningRequest,
};
use super::super::models::wallet_dtos::{
    NativeMultisigParticipant, NativeMultisigSignatureShare, NativeMultisigSigningRequest,
    NativeMultisigState, NativePreparedTransaction, NativePreparedTransactionKind,
    NativeTransactionFeePolicy, NativeTransactionTransferRequest,
};
use super::{transactions, PendingMultisigTransaction, TransactionBuilderState, XelisWallet};
use crate::api::error::{NativeXelisError, NativeXelisErrorCode};
use anyhow::{bail, Context, Result};
use flutter_rust_bridge::frb;
use indexmap::IndexSet;
use log::{info, warn};
use xelis_common::api::daemon::{GetMultisigParams, GetMultisigResult, MultisigState};
use xelis_common::api::wallet::BaseFeeMode;
use xelis_common::config::XELIS_ASSET;
use xelis_common::crypto::{Address, Hash, Hashable, PublicKey, Signature};
use xelis_common::serializer::Serializer;
use xelis_common::transaction::builder::{
    FeeBuilder, MultiSigBuilder, TransactionTypeBuilder, UnsignedTransaction,
};
use xelis_common::transaction::MultiSigPayload;

mod protocol;

#[cfg(test)]
mod test_support;

pub(super) struct PendingMultisigStore<T> {
    request: Option<(u64, Hash, T)>,
    next_generation: u64,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum PendingMultisigError {
    AlreadyPending,
    GenerationOverflow,
    NotFound,
    RequestMismatch,
}

impl std::fmt::Display for PendingMultisigError {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        formatter.write_str(match self {
            Self::AlreadyPending => "another multisig request is already pending",
            Self::GenerationOverflow => "multisig request generation overflow",
            Self::NotFound => "no multisig request is pending",
            Self::RequestMismatch => "the multisig request does not match the pending transaction",
        })
    }
}

impl std::error::Error for PendingMultisigError {}

impl<T> Default for PendingMultisigStore<T> {
    fn default() -> Self {
        Self {
            request: None,
            next_generation: 0,
        }
    }
}

impl<T> PendingMultisigStore<T> {
    pub fn insert(&mut self, signing_hash: Hash, payload: T) -> Result<u64> {
        if self.request.is_some() {
            return Err(PendingMultisigError::AlreadyPending.into());
        }

        let generation = self
            .next_generation
            .checked_add(1)
            .ok_or(PendingMultisigError::GenerationOverflow)?;
        self.next_generation = generation;
        self.request = Some((generation, signing_hash, payload));
        Ok(generation)
    }

    pub fn signing_hash(&self) -> Option<&Hash> {
        self.request
            .as_ref()
            .map(|(_, signing_hash, _)| signing_hash)
    }

    pub fn cancel(&mut self, request_id: u64, expected_signing_hash: &Hash) -> Result<()> {
        self.ensure_expected_request(request_id, expected_signing_hash)?;
        self.request = None;
        Ok(())
    }

    pub fn take_validated<R>(
        &mut self,
        request_id: u64,
        expected_signing_hash: &Hash,
        validate: impl FnOnce(&T) -> Result<R>,
    ) -> Result<(T, R)> {
        let validation = self.validate(request_id, expected_signing_hash, validate)?;

        let (_, _, payload) = self.request.take().ok_or(PendingMultisigError::NotFound)?;
        Ok((payload, validation))
    }

    pub fn validate<R>(
        &self,
        request_id: u64,
        expected_signing_hash: &Hash,
        validate: impl FnOnce(&T) -> Result<R>,
    ) -> Result<R> {
        self.ensure_expected_request(request_id, expected_signing_hash)?;
        let (_, _, payload) = self
            .request
            .as_ref()
            .ok_or(PendingMultisigError::NotFound)?;
        validate(payload)
    }

    fn ensure_expected_request(&self, request_id: u64, expected_signing_hash: &Hash) -> Result<()> {
        let (actual_request_id, actual_signing_hash, _) = self
            .request
            .as_ref()
            .ok_or(PendingMultisigError::NotFound)?;

        if *actual_request_id != request_id || actual_signing_hash != expected_signing_hash {
            return Err(PendingMultisigError::RequestMismatch.into());
        }

        Ok(())
    }
}

fn map_pending_multisig_error(
    error: anyhow::Error,
    fallback_code: NativeXelisErrorCode,
    fallback_kind: &'static str,
) -> NativeXelisError {
    if let Some(error) = error.downcast_ref::<PendingMultisigError>() {
        let (code, kind) = match error {
            PendingMultisigError::AlreadyPending => (
                NativeXelisErrorCode::Conflict,
                "MULTISIG_REQUEST_ALREADY_PENDING",
            ),
            PendingMultisigError::GenerationOverflow => (
                NativeXelisErrorCode::Internal,
                "MULTISIG_REQUEST_GENERATION_OVERFLOW",
            ),
            PendingMultisigError::NotFound => {
                (NativeXelisErrorCode::NotFound, "MULTISIG_REQUEST_NOT_FOUND")
            }
            PendingMultisigError::RequestMismatch => {
                (NativeXelisErrorCode::Conflict, "MULTISIG_REQUEST_MISMATCH")
            }
        };
        return NativeXelisError::xelis_wallet_flutter(code, kind, error.to_string());
    }

    NativeXelisError::from_wallet_operation(error, fallback_code, fallback_kind)
}

fn parse_multisig_signing_hash(value: &str) -> std::result::Result<Hash, NativeXelisError> {
    Hash::from_hex(value).map_err(|error| {
        NativeXelisError::from_wallet_operation(
            error.into(),
            NativeXelisErrorCode::InvalidInput,
            "MULTISIG_SIGNING_HASH_INVALID",
        )
    })
}

fn is_multisig_participant_address_valid(
    address: &Address,
    mainnet: bool,
    wallet_public_key: &PublicKey,
) -> bool {
    address.is_normal()
        && address.is_mainnet() == mainnet
        && address.get_public_key() != wallet_public_key
}

fn parse_multisig_participants(
    participants: Vec<String>,
    mainnet: bool,
    wallet_public_key: &PublicKey,
) -> Result<IndexSet<Address>> {
    let mut participant_addresses = IndexSet::with_capacity(participants.len());

    for participant in participants {
        let Ok(address) = Address::from_string(&participant) else {
            bail!("Invalid multisig participant address");
        };
        if !is_multisig_participant_address_valid(&address, mainnet, wallet_public_key) {
            bail!("Invalid multisig participant address");
        }
        if !participant_addresses.insert(address) {
            bail!("A multisig participant was provided more than once");
        }
    }

    Ok(participant_addresses)
}

#[derive(Debug)]
struct ResolvedMultisigSigningConfiguration {
    threshold: u8,
    participants: Vec<NativeMultisigParticipant>,
    signer_id: Option<u8>,
}

fn resolve_active_multisig_configuration(
    state: MultisigState,
    wallet_public_key: &PublicKey,
) -> Result<ResolvedMultisigSigningConfiguration> {
    let MultisigState::Active {
        participants,
        threshold,
    } = state
    else {
        bail!("The multisig configuration was not active for this request");
    };
    validate_multisig_setup(threshold, participants.len())?;

    let mut signer_id = None;
    let participants = participants
        .into_iter()
        .enumerate()
        .map(|(id, participant)| {
            if participant.get_public_key() == wallet_public_key {
                signer_id = Some(id as u8);
            }
            NativeMultisigParticipant {
                id: id as u8,
                address: participant.to_string(),
            }
        })
        .collect();

    Ok(ResolvedMultisigSigningConfiguration {
        threshold,
        participants,
        signer_id,
    })
}

#[cfg(test)]
async fn resolve_multisig_signing_configuration_with<F, Fut>(
    source: &str,
    wallet_public_key: &PublicKey,
    fetch_state: F,
) -> Result<ResolvedMultisigSigningConfiguration>
where
    F: FnOnce(Address) -> Fut,
    Fut: Future<Output = Result<MultisigState>>,
{
    let source = Address::from_string(source).context("Invalid multisig signing request source")?;
    let state = fetch_state(source).await?;

    resolve_active_multisig_configuration(state, wallet_public_key)
}

fn create_authorized_multisig_signature_share(
    signing_hash: &Hash,
    signer_id: Option<u8>,
    sign: impl FnOnce(&[u8]) -> Signature,
) -> Result<NativeMultisigSignatureShare> {
    let signer_id = signer_id
        .context("The opened wallet is not an authorized participant for this multisig request")?;
    let signature = sign(signing_hash.as_bytes());

    create_multisig_signature_share(signing_hash, signer_id, signature)
}

impl XelisWallet {
    pub async fn create_multisig_transfers_transaction(
        &self,
        transfers: Vec<NativeTransactionTransferRequest>,
        fee_policy: NativeTransactionFeePolicy,
    ) -> std::result::Result<NativeMultisigSigningRequest, NativeXelisError> {
        info!("Building transaction...");
        transactions::apply_fee_policy(0, fee_policy)?;
        let (transaction_type, _, _) = transactions::build_atomic_transfers(transfers)?;
        self.prepare_pending_multisig_transaction(transaction_type, fee_policy)
            .await
    }

    pub async fn create_multisig_transfer_all_transaction(
        &self,
        str_address: String,
        asset_hash: Option<String>,
        extra_data: Option<String>,
        encrypt_extra_data: Option<bool>,
        fee_policy: NativeTransactionFeePolicy,
    ) -> std::result::Result<NativeMultisigSigningRequest, NativeXelisError> {
        info!("Building multisig transfer all transaction...");
        transactions::apply_fee_policy(0, fee_policy)?;
        let asset = match asset_hash.as_deref() {
            None => XELIS_ASSET,
            Some(value) => transactions::parse_transaction_asset(value)?,
        };
        let destination = transactions::parse_transaction_destination(&str_address)?;
        let balance = {
            let storage = self.wallet.get_storage().read().await;
            storage
                .get_plaintext_balance_for(&asset)
                .await
                .map_err(|error| {
                    NativeXelisError::from_wallet_storage_operation(
                        error.into(),
                        "MULTISIG_TRANSFER_ALL_BALANCE_READ_FAILED",
                    )
                })?
        };
        let estimated_type = transactions::build_transfer_all_type(
            destination.clone(),
            balance,
            0,
            asset.clone(),
            extra_data.clone(),
            encrypt_extra_data,
        )
        .map_err(|error| {
            NativeXelisError::from_wallet_operation(
                error,
                NativeXelisErrorCode::InsufficientFunds,
                "MULTISIG_TRANSFER_ALL_BALANCE_INSUFFICIENT",
            )
        })?;
        let target_fee = self.estimate_target_fee(estimated_type, fee_policy).await?;
        let amount = transactions::amount_after_fee(
            balance,
            target_fee,
            &asset,
            "Insufficient balance for fees",
        )
        .map_err(|error| {
            NativeXelisError::from_wallet_operation(
                error,
                NativeXelisErrorCode::InsufficientFunds,
                "MULTISIG_TRANSFER_ALL_BALANCE_INSUFFICIENT",
            )
        })?;
        let transaction_type =
            TransactionTypeBuilder::Transfers(vec![transactions::build_transfer(
                destination,
                amount,
                asset,
                extra_data,
                encrypt_extra_data,
            )]);

        self.prepare_pending_multisig_transaction_with_fee(transaction_type, target_fee)
            .await
    }

    pub async fn create_multisig_burn_transaction(
        &self,
        amount: u64,
        asset_hash: String,
        fee_policy: NativeTransactionFeePolicy,
    ) -> std::result::Result<NativeMultisigSigningRequest, NativeXelisError> {
        info!("Building burn transaction...");
        transactions::apply_fee_policy(0, fee_policy)?;
        if amount == 0 {
            return Err(NativeXelisError::xelis_wallet_flutter(
                NativeXelisErrorCode::InvalidInput,
                "MULTISIG_TRANSACTION_AMOUNT_INVALID",
                "Burn amount must be greater than zero",
            ));
        }
        let asset = transactions::parse_transaction_asset(&asset_hash)?;
        self.prepare_pending_multisig_transaction(
            transactions::build_burn_type(asset, amount),
            fee_policy,
        )
        .await
    }

    pub async fn create_multisig_burn_all_transaction(
        &self,
        asset_hash: String,
        fee_policy: NativeTransactionFeePolicy,
    ) -> std::result::Result<NativeMultisigSigningRequest, NativeXelisError> {
        info!("Building burn all transaction...");
        transactions::apply_fee_policy(0, fee_policy)?;
        let asset = transactions::parse_transaction_asset(&asset_hash)?;
        let balance = {
            let storage = self.wallet.get_storage().read().await;
            storage
                .get_plaintext_balance_for(&asset)
                .await
                .map_err(|error| {
                    NativeXelisError::from_wallet_storage_operation(
                        error.into(),
                        "MULTISIG_BURN_ALL_BALANCE_READ_FAILED",
                    )
                })?
        };
        let estimated_type =
            transactions::build_burn_all_type(asset.clone(), balance, 0).map_err(|error| {
                NativeXelisError::from_wallet_operation(
                    error,
                    NativeXelisErrorCode::InsufficientFunds,
                    "MULTISIG_BURN_ALL_BALANCE_INSUFFICIENT",
                )
            })?;
        let target_fee = self.estimate_target_fee(estimated_type, fee_policy).await?;
        let transaction_type = transactions::build_burn_all_type(asset, balance, target_fee)
            .map_err(|error| {
                NativeXelisError::from_wallet_operation(
                    error,
                    NativeXelisErrorCode::InsufficientFunds,
                    "MULTISIG_BURN_ALL_BALANCE_INSUFFICIENT",
                )
            })?;

        self.prepare_pending_multisig_transaction_with_fee(transaction_type, target_fee)
            .await
    }

    pub async fn get_multisig_state(
        &self,
    ) -> std::result::Result<Option<NativeMultisigState>, NativeXelisError> {
        let storage = self.wallet.get_storage().read().await;
        let multisig = storage.get_multisig_state().await.map_err(|error| {
            NativeXelisError::from_wallet_storage_operation(
                error.into(),
                "MULTISIG_STATE_READ_FAILED",
            )
        })?;

        Ok(multisig.map(|multisig| NativeMultisigState {
            threshold: multisig.payload.threshold,
            participants: multisig
                .payload
                .participants
                .iter()
                .enumerate()
                .map(|(id, participant)| NativeMultisigParticipant {
                    id: id as u8,
                    address: participant
                        .as_address(self.wallet.get_network().is_mainnet())
                        .to_string(),
                })
                .collect(),
            topoheight: multisig.topoheight,
        }))
    }

    pub async fn multisig_setup(
        &self,
        threshold: u8,
        participants: Vec<String>,
        fee_policy: NativeTransactionFeePolicy,
    ) -> std::result::Result<NativePreparedTransaction, NativeXelisError> {
        info!("Preparing multisig setup transaction...");
        transactions::apply_fee_policy(0, fee_policy)?;
        validate_multisig_setup(threshold, participants.len()).map_err(|error| {
            NativeXelisError::from_wallet_operation(
                error,
                NativeXelisErrorCode::InvalidInput,
                "MULTISIG_SETUP_INVALID",
            )
        })?;

        let participant_addresses = parse_multisig_participants(
            participants,
            self.wallet.get_network().is_mainnet(),
            self.wallet.get_public_key(),
        )
        .map_err(|error| {
            NativeXelisError::from_wallet_operation(
                error,
                NativeXelisErrorCode::InvalidInput,
                "MULTISIG_SETUP_PARTICIPANTS_INVALID",
            )
        })?;
        let prepared_participants = participant_addresses
            .iter()
            .enumerate()
            .map(|(id, participant)| NativeMultisigParticipant {
                id: id as u8,
                address: participant.to_string(),
            })
            .collect();

        {
            let storage = self.wallet.get_storage().read().await;
            if storage
                .get_multisig_state()
                .await
                .map_err(|error| {
                    NativeXelisError::from_wallet_storage_operation(
                        error.into(),
                        "MULTISIG_SETUP_STATE_READ_FAILED",
                    )
                })?
                .is_some()
            {
                return Err(NativeXelisError::xelis_wallet_flutter(
                    NativeXelisErrorCode::Conflict,
                    "MULTISIG_ALREADY_CONFIGURED",
                    "Multisig is already configured",
                ));
            }
        }

        let transaction_type = TransactionTypeBuilder::MultiSig(MultiSigBuilder {
            participants: participant_addresses,
            threshold,
        });
        let preparation =
            transactions::PreparedTransactionPreparationGuard::begin(&self.prepared_transaction)
                .map_err(transactions::prepared_transaction_error)?;
        let target_fee = self
            .estimate_target_fee(transaction_type.clone(), fee_policy)
            .await?;

        self.create_and_commit_prepared_transaction(
            preparation,
            transaction_type,
            NativePreparedTransactionKind::MultisigSetup {
                threshold,
                participants: prepared_participants,
            },
            Vec::new(),
            target_fee,
            "Prepared multisig setup transaction",
        )
        .await
    }

    #[frb(sync)]
    pub fn is_address_valid_for_multisig(&self, address: String) -> Result<bool> {
        let address = match Address::from_string(&address) {
            Ok(address) => address,
            Err(_) => {
                warn!("Invalid address");
                return Ok(false);
            }
        };

        let mainnet = self.wallet.get_network().is_mainnet();
        Ok(is_multisig_participant_address_valid(
            &address,
            mainnet,
            self.wallet.get_public_key(),
        ))
    }

    pub async fn init_delete_multisig(
        &self,
        fee_policy: NativeTransactionFeePolicy,
    ) -> std::result::Result<NativeMultisigSigningRequest, NativeXelisError> {
        info!("Preparing multisig deletion transaction...");
        transactions::apply_fee_policy(0, fee_policy)?;
        self.prepare_pending_multisig_transaction(
            TransactionTypeBuilder::MultiSig(MultiSigBuilder {
                participants: IndexSet::new(),
                threshold: 0,
            }),
            fee_policy,
        )
        .await
    }

    pub async fn finalize_multisig_transaction(
        &self,
        request_id: u64,
        signing_hash: String,
        signature_shares: Vec<String>,
    ) -> std::result::Result<NativePreparedTransaction, NativeXelisError> {
        let expected_signing_hash = parse_multisig_signing_hash(&signing_hash)?;
        let signatures = signature_shares
            .iter()
            .map(|share| parse_multisig_signature_share(share, &expected_signing_hash))
            .collect::<Result<Vec<_>>>()
            .map_err(|error| {
                NativeXelisError::from_wallet_operation(
                    error,
                    NativeXelisErrorCode::InvalidInput,
                    "MULTISIG_SIGNATURE_SHARES_INVALID",
                )
            })?;
        let preparation =
            transactions::PreparedTransactionPreparationGuard::begin(&self.prepared_transaction)
                .map_err(transactions::prepared_transaction_error)?;
        let (pending, multisig) = self
            .pending_multisig
            .write()
            .take_validated(request_id, &expected_signing_hash, |pending| {
                build_verified_multisig(&expected_signing_hash, &pending.configuration, &signatures)
            })
            .map_err(|error| {
                map_pending_multisig_error(
                    error,
                    NativeXelisErrorCode::InvalidInput,
                    "MULTISIG_FINALIZATION_INVALID",
                )
            })?;

        let PendingMultisigTransaction {
            mut unsigned,
            state,
            transaction_preview,
            ..
        } = pending;

        unsigned.set_multisig(multisig);

        let tx = unsigned.finalize(self.wallet.get_keypair());
        transactions::log_transaction_context(
            "Prepared finalized multisig transaction",
            &tx,
            &state,
        );

        let hash = tx.hash().clone();
        let fee = tx.get_fee();
        let preparation_id = preparation
            .commit(
                hash.clone(),
                transactions::PreparedWalletTransaction::without_review_extra_data(tx, state),
            )
            .map_err(transactions::prepared_transaction_error)?;

        Ok(NativePreparedTransaction {
            hash: hash.to_hex(),
            preparation_id,
            fee,
            transaction: NativePreparedTransactionKind::MultisigFinalized {
                transaction: transaction_preview,
            },
        })
    }

    #[frb(sync)]
    pub fn cancel_pending_multisig_request(
        &self,
        request_id: u64,
        signing_hash: String,
    ) -> std::result::Result<(), NativeXelisError> {
        let expected_signing_hash = parse_multisig_signing_hash(&signing_hash)?;
        self.pending_multisig
            .write()
            .cancel(request_id, &expected_signing_hash)
            .map_err(|error| {
                map_pending_multisig_error(
                    error,
                    NativeXelisErrorCode::NotFound,
                    "MULTISIG_REQUEST_CANCELLATION_FAILED",
                )
            })
    }

    pub fn inspect_multisig_signature_share(
        &self,
        request_id: u64,
        signing_hash: String,
        encoded: String,
    ) -> std::result::Result<NativeMultisigSignatureShare, NativeXelisError> {
        let expected_signing_hash = parse_multisig_signing_hash(&signing_hash)?;
        let signature =
            parse_multisig_signature_share(&encoded, &expected_signing_hash).map_err(|error| {
                NativeXelisError::from_wallet_operation(
                    error,
                    NativeXelisErrorCode::InvalidInput,
                    "MULTISIG_SIGNATURE_SHARE_INVALID",
                )
            })?;
        self.pending_multisig
            .read()
            .validate(request_id, &expected_signing_hash, |pending| {
                verify_multisig_signature(
                    &expected_signing_hash,
                    &pending.configuration,
                    &signature,
                )
            })
            .map_err(|error| {
                map_pending_multisig_error(
                    error,
                    NativeXelisErrorCode::InvalidInput,
                    "MULTISIG_SIGNATURE_SHARE_VERIFICATION_FAILED",
                )
            })?;

        Ok(NativeMultisigSignatureShare {
            encoded: encoded.trim().to_owned(),
            signing_hash: expected_signing_hash.to_hex(),
            signer_id: signature.id,
            signature: signature.signature,
        })
    }

    pub async fn inspect_multisig_signing_request(
        &self,
        encoded: String,
    ) -> std::result::Result<NativeMultisigSigningRequest, NativeXelisError> {
        let parsed = parse_multisig_signing_request(&encoded, *self.wallet.get_network()).map_err(
            |error| {
                NativeXelisError::from_wallet_operation(
                    error,
                    NativeXelisErrorCode::InvalidInput,
                    "MULTISIG_SIGNING_REQUEST_INVALID",
                )
            },
        )?;
        let configuration = self.resolve_multisig_signing_configuration(&parsed).await?;

        Ok(parsed.into_request(
            None,
            configuration.threshold,
            configuration.participants,
            configuration.signer_id,
        ))
    }

    pub async fn sign_multisig_signing_request(
        &self,
        encoded: String,
    ) -> std::result::Result<NativeMultisigSignatureShare, NativeXelisError> {
        let parsed = parse_multisig_signing_request(&encoded, *self.wallet.get_network()).map_err(
            |error| {
                NativeXelisError::from_wallet_operation(
                    error,
                    NativeXelisErrorCode::InvalidInput,
                    "MULTISIG_SIGNING_REQUEST_INVALID",
                )
            },
        )?;
        let configuration = self.resolve_multisig_signing_configuration(&parsed).await?;

        create_authorized_multisig_signature_share(
            &parsed.signing_hash,
            configuration.signer_id,
            |data| self.wallet.sign_data(data),
        )
        .map_err(|error| {
            NativeXelisError::from_wallet_operation(
                error,
                NativeXelisErrorCode::InvalidInput,
                "MULTISIG_PARTICIPANT_UNAUTHORIZED",
            )
        })
    }

    fn store_pending_multisig_transaction(
        &self,
        unsigned: UnsignedTransaction,
        state: TransactionBuilderState,
        transaction_type: TransactionTypeBuilder,
        configuration: MultiSigPayload,
        target_fee: u64,
    ) -> std::result::Result<NativeMultisigSigningRequest, NativeXelisError> {
        let signing_hash = unsigned.get_hash_for_multisig();
        let mut request = create_multisig_signing_request(
            &unsigned,
            &transaction_type,
            &configuration,
            *self.wallet.get_network(),
            self.wallet.get_keypair(),
        )
        .map_err(|error| {
            NativeXelisError::from_wallet_operation(
                error,
                NativeXelisErrorCode::Serialization,
                "MULTISIG_SIGNING_REQUEST_CREATION_FAILED",
            )
        })?;
        if request.fee != target_fee {
            return Err(NativeXelisError::xelis_wallet_flutter(
                NativeXelisErrorCode::Internal,
                "MULTISIG_TRANSACTION_FEE_MISMATCH",
                format!(
                    "Prepared multisig fee {} differs from requested fixed fee {target_fee}",
                    request.fee
                ),
            ));
        }
        let transaction_preview = request.transaction.clone();
        let request_id = self
            .pending_multisig
            .write()
            .insert(
                signing_hash.clone(),
                PendingMultisigTransaction {
                    unsigned,
                    state,
                    configuration,
                    transaction_preview,
                },
            )
            .map_err(|error| {
                map_pending_multisig_error(
                    error,
                    NativeXelisErrorCode::Conflict,
                    "MULTISIG_REQUEST_STORE_FAILED",
                )
            })?;
        request.request_id = Some(request_id);

        info!("Unsigned multisig transaction created");
        Ok(request)
    }

    async fn active_multisig_configuration(
        &self,
    ) -> std::result::Result<MultiSigPayload, NativeXelisError> {
        let storage = self.wallet.get_storage().read().await;
        storage
            .get_multisig_state()
            .await
            .map_err(|error| {
                NativeXelisError::from_wallet_storage_operation(
                    error.into(),
                    "MULTISIG_CONFIGURATION_READ_FAILED",
                )
            })?
            .map(|multisig| multisig.payload.clone())
            .ok_or_else(|| {
                NativeXelisError::xelis_wallet_flutter(
                    NativeXelisErrorCode::NotFound,
                    "MULTISIG_CONFIGURATION_NOT_FOUND",
                    "No multisig configuration is active",
                )
            })
    }

    async fn prepare_pending_multisig_transaction(
        &self,
        transaction_type: TransactionTypeBuilder,
        fee_policy: NativeTransactionFeePolicy,
    ) -> std::result::Result<NativeMultisigSigningRequest, NativeXelisError> {
        let target_fee = self
            .estimate_target_fee(transaction_type.clone(), fee_policy)
            .await?;
        self.prepare_pending_multisig_transaction_with_fee(transaction_type, target_fee)
            .await
    }

    async fn prepare_pending_multisig_transaction_with_fee(
        &self,
        transaction_type: TransactionTypeBuilder,
        target_fee: u64,
    ) -> std::result::Result<NativeMultisigSigningRequest, NativeXelisError> {
        if self.pending_multisig.read().signing_hash().is_some() {
            return Err(NativeXelisError::xelis_wallet_flutter(
                NativeXelisErrorCode::Conflict,
                "MULTISIG_REQUEST_ALREADY_PENDING",
                "Another multisig request is already pending",
            ));
        }
        let configuration = self.active_multisig_configuration().await?;
        let (unsigned, state) = self
            .build_unsigned_transaction(
                transaction_type.clone(),
                FeeBuilder::Fixed(target_fee),
                configuration.threshold,
            )
            .await?;
        self.store_pending_multisig_transaction(
            unsigned,
            state,
            transaction_type,
            configuration,
            target_fee,
        )
    }

    async fn resolve_multisig_signing_configuration(
        &self,
        request: &ParsedMultisigSigningRequest,
    ) -> std::result::Result<ResolvedMultisigSigningConfiguration, NativeXelisError> {
        // The opened participant wallet only stores multisig state for its own
        // address, while this request belongs to another source wallet. Resolve
        // that source's active configuration from the node so inspection can
        // derive the participant ID and signing can reject an unauthorized key.
        let source = Address::from_string(&request.source).map_err(|error| {
            NativeXelisError::from_wallet_operation(
                error.into(),
                NativeXelisErrorCode::InvalidInput,
                "MULTISIG_SIGNING_REQUEST_SOURCE_INVALID",
            )
        })?;
        let network_handler = self
            .wallet
            .get_network_handler()
            .lock()
            .await
            .clone()
            .ok_or_else(|| {
                NativeXelisError::xelis_wallet_flutter(
                    NativeXelisErrorCode::Offline,
                    "MULTISIG_CONFIGURATION_REQUIRES_ONLINE_WALLET",
                    "The wallet must be online to verify a multisig signing request",
                )
            })?;
        // The daemon's `get_multisig_at_topoheight` endpoint performs an exact
        // version lookup. A transaction reference is not the configuration's
        // activation topoheight, so use the latest configuration that consensus
        // would apply when the transaction is submitted.
        let result: GetMultisigResult = network_handler
            .get_api()
            .client()
            .call_with(
                "get_multisig",
                &GetMultisigParams {
                    address: Cow::Borrowed(&source),
                },
            )
            .await
            .map_err(|error| {
                NativeXelisError::from_wallet_operation(
                    error.into(),
                    NativeXelisErrorCode::Network,
                    "MULTISIG_CONFIGURATION_LOOKUP_FAILED",
                )
            })?;

        resolve_active_multisig_configuration(result.state, self.wallet.get_public_key()).map_err(
            |error| {
                NativeXelisError::from_wallet_operation(
                    error,
                    NativeXelisErrorCode::RemoteRejected,
                    "MULTISIG_CONFIGURATION_INVALID",
                )
            },
        )
    }

    async fn build_unsigned_transaction(
        &self,
        tx_type: TransactionTypeBuilder,
        fee: FeeBuilder,
        threshold: u8,
    ) -> std::result::Result<(UnsignedTransaction, TransactionBuilderState), NativeXelisError> {
        let storage = self.wallet.get_storage().write().await;
        let mut state = self
            .wallet
            .create_transaction_state_with_storage(
                &storage,
                &tx_type,
                fee,
                BaseFeeMode::None,
                None,
                None,
            )
            .await
            .map_err(|error| {
                NativeXelisError::from_wallet_operation(
                    error.into(),
                    NativeXelisErrorCode::OperationFailed,
                    "MULTISIG_TRANSACTION_STATE_CREATION_FAILED",
                )
            })?;

        let transaction_version = storage.get_tx_version().await.map_err(|error| {
            NativeXelisError::from_wallet_storage_operation(
                error.into(),
                "MULTISIG_TRANSACTION_VERSION_READ_FAILED",
            )
        })?;

        let unsigned = self
            .wallet
            .create_unsigned_transaction(
                &mut state,
                Some(threshold),
                tx_type,
                fee,
                transaction_version,
            )
            .map_err(|error| {
                NativeXelisError::from_wallet_operation(
                    error.into(),
                    NativeXelisErrorCode::OperationFailed,
                    "MULTISIG_UNSIGNED_TRANSACTION_CREATION_FAILED",
                )
            })?;
        info!("Unsigned multisig transaction created");
        Ok((unsigned, state))
    }
}

#[cfg(test)]
mod tests;
