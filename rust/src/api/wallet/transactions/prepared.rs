use std::{error::Error as StdError, fmt, mem};

use log::{error, warn};
use parking_lot::RwLock;
use xelis_common::crypto::Hash;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub(in crate::api::wallet) enum PreparedTransactionError {
    PreparationInProgress,
    ReplacementDuringSubmission,
    CancellationDuringSubmission,
    AlreadySubmitting,
    CannotDelete,
    NotFound,
    GenerationOverflow,
    PreparationStateInconsistent,
    CancellationStateInconsistent,
    SubmissionStateInconsistent,
    EmptyGuard,
}

impl PreparedTransactionError {
    pub(super) fn native_kind(self) -> &'static str {
        match self {
            Self::PreparationInProgress => "PREPARED_TRANSACTION_PREPARATION_IN_PROGRESS",
            Self::ReplacementDuringSubmission => "PREPARED_TRANSACTION_SUBMISSION_IN_PROGRESS",
            Self::CancellationDuringSubmission => "PREPARED_TRANSACTION_CANCELLATION_IN_PROGRESS",
            Self::AlreadySubmitting => "PREPARED_TRANSACTION_ALREADY_SUBMITTING",
            Self::CannotDelete | Self::NotFound => "PREPARED_TRANSACTION_NOT_FOUND",
            Self::GenerationOverflow => "PREPARED_TRANSACTION_GENERATION_OVERFLOW",
            Self::PreparationStateInconsistent => {
                "PREPARED_TRANSACTION_PREPARATION_STATE_INCONSISTENT"
            }
            Self::CancellationStateInconsistent => {
                "PREPARED_TRANSACTION_CANCELLATION_STATE_INCONSISTENT"
            }
            Self::SubmissionStateInconsistent => {
                "PREPARED_TRANSACTION_SUBMISSION_STATE_INCONSISTENT"
            }
            Self::EmptyGuard => "PREPARED_TRANSACTION_GUARD_EMPTY",
        }
    }
}

impl fmt::Display for PreparedTransactionError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(match self {
            Self::PreparationInProgress => {
                "Cannot replace a prepared transaction while another preparation is in progress"
            }
            Self::ReplacementDuringSubmission => {
                "Cannot replace a prepared transaction while another transaction is being submitted"
            }
            Self::CancellationDuringSubmission => {
                "Cannot cancel a transaction while it is being submitted"
            }
            Self::AlreadySubmitting => "Transaction is already being submitted",
            Self::CannotDelete => "Cannot delete prepared transaction",
            Self::NotFound => "Cannot find prepared transaction",
            Self::GenerationOverflow => "Prepared transaction generation overflow",
            Self::PreparationStateInconsistent => {
                "Prepared transaction preparation state is inconsistent"
            }
            Self::CancellationStateInconsistent => {
                "Prepared transaction state changed during cancellation"
            }
            Self::SubmissionStateInconsistent => {
                "Prepared transaction submission state is inconsistent"
            }
            Self::EmptyGuard => "Prepared transaction guard is empty",
        })
    }
}

impl StdError for PreparedTransactionError {}

type PreparedResult<T> = std::result::Result<T, PreparedTransactionError>;

pub(super) enum PreparedTransactionState<T> {
    Empty,
    Ready {
        generation: u64,
        hash: Hash,
        transaction: T,
    },
    InFlight {
        generation: u64,
        hash: Hash,
    },
}

impl<T> Default for PreparedTransactionState<T> {
    fn default() -> Self {
        Self::Empty
    }
}

pub(in crate::api::wallet) struct PreparedTransactionStore<T> {
    pub(super) state: PreparedTransactionState<T>,
    next_generation: u64,
    active_preparation: Option<u64>,
}

impl<T> Default for PreparedTransactionStore<T> {
    fn default() -> Self {
        Self {
            state: PreparedTransactionState::Empty,
            next_generation: 0,
            active_preparation: None,
        }
    }
}

impl<T> PreparedTransactionStore<T> {
    fn allocate_generation(&mut self) -> PreparedResult<u64> {
        let generation = self
            .next_generation
            .checked_add(1)
            .ok_or(PreparedTransactionError::GenerationOverflow)?;
        self.next_generation = generation;
        Ok(generation)
    }

    pub(in crate::api::wallet) fn ensure_replaceable(&self) -> PreparedResult<()> {
        if self.active_preparation.is_some() {
            return Err(PreparedTransactionError::PreparationInProgress);
        }
        if matches!(self.state, PreparedTransactionState::InFlight { .. }) {
            return Err(PreparedTransactionError::ReplacementDuringSubmission);
        }

        Ok(())
    }

    fn ensure_slot_operation_available(&self) -> PreparedResult<()> {
        if self.active_preparation.is_some() {
            return Err(PreparedTransactionError::PreparationInProgress);
        }
        Ok(())
    }

    pub(super) fn ensure_ready_exact(&self, generation: u64, hash: &Hash) -> PreparedResult<()> {
        self.ensure_slot_operation_available()?;
        match &self.state {
            PreparedTransactionState::Ready {
                generation: prepared_generation,
                hash: prepared_hash,
                ..
            } if *prepared_generation == generation && prepared_hash == hash => Ok(()),
            PreparedTransactionState::InFlight {
                generation: submitted_generation,
                hash: submitted_hash,
            } if *submitted_generation == generation && submitted_hash == hash => {
                Err(PreparedTransactionError::AlreadySubmitting)
            }
            _ => Err(PreparedTransactionError::NotFound),
        }
    }

    pub(super) fn ready_exact(&self, generation: u64, hash: &Hash) -> PreparedResult<&T> {
        self.ensure_ready_exact(generation, hash)?;
        match &self.state {
            PreparedTransactionState::Ready { transaction, .. } => Ok(transaction),
            _ => Err(PreparedTransactionError::NotFound),
        }
    }

    pub(in crate::api::wallet) fn replace(
        &mut self,
        hash: Hash,
        transaction: T,
    ) -> PreparedResult<u64> {
        self.ensure_replaceable()?;
        let generation = self.allocate_generation()?;
        self.state = PreparedTransactionState::Ready {
            generation,
            hash,
            transaction,
        };
        Ok(generation)
    }

    fn begin_preparation(&mut self) -> PreparedResult<u64> {
        self.ensure_replaceable()?;
        let generation = self.allocate_generation()?;
        self.active_preparation = Some(generation);
        Ok(generation)
    }

    fn commit_preparation(
        &mut self,
        generation: u64,
        hash: Hash,
        transaction: T,
    ) -> PreparedResult<()> {
        if self.active_preparation != Some(generation) {
            return Err(PreparedTransactionError::PreparationStateInconsistent);
        }
        if matches!(self.state, PreparedTransactionState::InFlight { .. }) {
            return Err(PreparedTransactionError::ReplacementDuringSubmission);
        }

        self.state = PreparedTransactionState::Ready {
            generation,
            hash,
            transaction,
        };
        self.active_preparation = None;
        Ok(())
    }

    fn abandon_preparation(&mut self, generation: u64) -> bool {
        if self.active_preparation == Some(generation) {
            self.active_preparation = None;
            true
        } else {
            false
        }
    }

    pub(super) fn cancel(&mut self, hash: &Hash) -> PreparedResult<T> {
        self.ensure_slot_operation_available()?;
        match &self.state {
            PreparedTransactionState::InFlight {
                hash: submitted_hash,
                ..
            } if submitted_hash == hash => {
                return Err(PreparedTransactionError::CancellationDuringSubmission)
            }
            PreparedTransactionState::Ready {
                hash: prepared_hash,
                ..
            } if prepared_hash == hash => {}
            _ => return Err(PreparedTransactionError::CannotDelete),
        }

        match mem::take(&mut self.state) {
            PreparedTransactionState::Ready { transaction, .. } => Ok(transaction),
            previous_state => {
                self.state = previous_state;
                Err(PreparedTransactionError::CancellationStateInconsistent)
            }
        }
    }

    pub(super) fn cancel_exact(&mut self, generation: u64, hash: &Hash) -> PreparedResult<T> {
        self.ensure_slot_operation_available()?;
        match &self.state {
            PreparedTransactionState::InFlight {
                generation: submitted_generation,
                hash: submitted_hash,
            } if *submitted_generation == generation && submitted_hash == hash => {
                return Err(PreparedTransactionError::CancellationDuringSubmission)
            }
            PreparedTransactionState::Ready {
                generation: prepared_generation,
                hash: prepared_hash,
                ..
            } if *prepared_generation == generation && prepared_hash == hash => {}
            _ => return Err(PreparedTransactionError::NotFound),
        }

        match mem::take(&mut self.state) {
            PreparedTransactionState::Ready { transaction, .. } => Ok(transaction),
            previous_state => {
                self.state = previous_state;
                Err(PreparedTransactionError::CancellationStateInconsistent)
            }
        }
    }

    fn take_for_submission(&mut self, hash: &Hash) -> PreparedResult<(u64, T)> {
        self.ensure_slot_operation_available()?;
        match &self.state {
            PreparedTransactionState::InFlight {
                hash: submitted_hash,
                ..
            } if submitted_hash == hash => return Err(PreparedTransactionError::AlreadySubmitting),
            PreparedTransactionState::Ready {
                hash: prepared_hash,
                ..
            } if prepared_hash == hash => {}
            _ => return Err(PreparedTransactionError::NotFound),
        }

        self.take_ready_for_submission()
    }

    fn take_for_submission_exact(&mut self, generation: u64, hash: &Hash) -> PreparedResult<T> {
        self.ensure_slot_operation_available()?;
        match &self.state {
            PreparedTransactionState::InFlight {
                generation: submitted_generation,
                hash: submitted_hash,
            } if *submitted_generation == generation && submitted_hash == hash => {
                return Err(PreparedTransactionError::AlreadySubmitting)
            }
            PreparedTransactionState::Ready {
                generation: prepared_generation,
                hash: prepared_hash,
                ..
            } if *prepared_generation == generation && prepared_hash == hash => {}
            _ => return Err(PreparedTransactionError::NotFound),
        }

        let (stored_generation, transaction) = self.take_ready_for_submission()?;
        if stored_generation != generation {
            return Err(PreparedTransactionError::SubmissionStateInconsistent);
        }
        Ok(transaction)
    }

    fn take_ready_for_submission(&mut self) -> PreparedResult<(u64, T)> {
        match mem::take(&mut self.state) {
            PreparedTransactionState::Ready {
                generation,
                hash,
                transaction,
            } => {
                self.state = PreparedTransactionState::InFlight { generation, hash };
                Ok((generation, transaction))
            }
            previous_state => {
                self.state = previous_state;
                Err(PreparedTransactionError::SubmissionStateInconsistent)
            }
        }
    }

    fn restore_after_submission(
        &mut self,
        generation: u64,
        hash: Hash,
        transaction: T,
    ) -> PreparedResult<()> {
        match &self.state {
            PreparedTransactionState::InFlight {
                generation: submitted_generation,
                hash: submitted_hash,
            } if *submitted_generation == generation && submitted_hash == &hash => {
                self.state = PreparedTransactionState::Ready {
                    generation,
                    hash,
                    transaction,
                };
                Ok(())
            }
            _ => Err(PreparedTransactionError::SubmissionStateInconsistent),
        }
    }

    fn finish_submission(&mut self, generation: u64, hash: &Hash) -> bool {
        if matches!(
            &self.state,
            PreparedTransactionState::InFlight {
                generation: submitted_generation,
                hash: submitted_hash,
            } if *submitted_generation == generation && submitted_hash == hash
        ) {
            self.state = PreparedTransactionState::Empty;
            true
        } else {
            false
        }
    }
}

pub(in crate::api::wallet) struct PreparedTransactionPreparationGuard<'a, T> {
    store: &'a RwLock<PreparedTransactionStore<T>>,
    generation: u64,
    active: bool,
}

impl<'a, T> PreparedTransactionPreparationGuard<'a, T> {
    pub(in crate::api::wallet) fn begin(
        store: &'a RwLock<PreparedTransactionStore<T>>,
    ) -> PreparedResult<Self> {
        let generation = store.write().begin_preparation()?;
        Ok(Self {
            store,
            generation,
            active: true,
        })
    }

    pub(in crate::api::wallet) fn commit(
        mut self,
        hash: Hash,
        transaction: T,
    ) -> PreparedResult<u64> {
        self.store
            .write()
            .commit_preparation(self.generation, hash, transaction)?;
        self.active = false;
        Ok(self.generation)
    }
}

impl<T> Drop for PreparedTransactionPreparationGuard<'_, T> {
    fn drop(&mut self) {
        if self.active && !self.store.write().abandon_preparation(self.generation) {
            error!(
                "Prepared transaction generation {} could not be abandoned cleanly",
                self.generation
            );
        }
    }
}

pub(super) struct PreparedTransactionGuard<'a, T> {
    store: &'a RwLock<PreparedTransactionStore<T>>,
    generation: u64,
    hash: Hash,
    transaction: Option<T>,
}

impl<'a, T> PreparedTransactionGuard<'a, T> {
    pub(super) fn take(
        store: &'a RwLock<PreparedTransactionStore<T>>,
        hash: Hash,
    ) -> PreparedResult<Self> {
        let (generation, transaction) = store.write().take_for_submission(&hash)?;
        Ok(Self {
            store,
            generation,
            hash,
            transaction: Some(transaction),
        })
    }

    pub(super) fn take_exact(
        store: &'a RwLock<PreparedTransactionStore<T>>,
        generation: u64,
        hash: Hash,
    ) -> PreparedResult<Self> {
        let transaction = store.write().take_for_submission_exact(generation, &hash)?;
        Ok(Self {
            store,
            generation,
            hash,
            transaction: Some(transaction),
        })
    }

    pub(super) fn transaction(&self) -> PreparedResult<&T> {
        self.transaction
            .as_ref()
            .ok_or(PreparedTransactionError::EmptyGuard)
    }

    pub(super) fn restore(mut self) -> PreparedResult<()> {
        let transaction = self
            .transaction
            .take()
            .ok_or(PreparedTransactionError::EmptyGuard)?;
        self.store
            .write()
            .restore_after_submission(self.generation, self.hash.clone(), transaction)
    }

    pub(super) fn finish(mut self) -> PreparedResult<T> {
        let transaction = self
            .transaction
            .take()
            .ok_or(PreparedTransactionError::EmptyGuard)?;

        if !self
            .store
            .write()
            .finish_submission(self.generation, &self.hash)
        {
            self.transaction = Some(transaction);
            return Err(PreparedTransactionError::SubmissionStateInconsistent);
        }

        Ok(transaction)
    }
}

impl<T> Drop for PreparedTransactionGuard<'_, T> {
    fn drop(&mut self) {
        if let Some(transaction) = self.transaction.take() {
            if let Err(error) = self.store.write().restore_after_submission(
                self.generation,
                self.hash.clone(),
                transaction,
            ) {
                error!(
                    "Prepared transaction could not be restored after an interrupted submission: {error}"
                );
            } else {
                warn!(
                    "Prepared transaction {} restored after an interrupted submission",
                    self.hash
                );
            }
        }
    }
}

#[cfg(test)]
mod tests;
