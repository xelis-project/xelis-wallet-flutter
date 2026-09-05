use std::{
    collections::HashMap,
    fmt,
    sync::{
        atomic::{AtomicU64, Ordering},
        Arc, Weak,
    },
};

use xelis_wallet::api::AppState;

pub(super) const XSWD_SESSION_REFERENCE_EXHAUSTED: &str = "XSWD_SESSION_REFERENCE_EXHAUSTED";
pub(super) const XSWD_SESSION_REFERENCE_INVALID: &str = "XSWD_SESSION_REFERENCE_INVALID";
static NEXT_XSWD_SESSION_REFERENCE: AtomicU64 = AtomicU64::new(1);

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub(super) enum XswdSessionReferenceError {
    Exhausted,
    Invalid,
}

impl XswdSessionReferenceError {
    pub(super) fn code(self) -> &'static str {
        match self {
            Self::Exhausted => XSWD_SESSION_REFERENCE_EXHAUSTED,
            Self::Invalid => XSWD_SESSION_REFERENCE_INVALID,
        }
    }
}

impl fmt::Display for XswdSessionReferenceError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(self.code())
    }
}

impl std::error::Error for XswdSessionReferenceError {}

#[derive(Default)]
#[flutter_rust_bridge::frb(ignore)]
pub(crate) struct XswdSessionRegistry {
    pub(super) sessions: HashMap<u64, XswdSessionEntry>,
}

pub(super) struct XswdSessionEntry {
    state: Weak<AppState>,
    active: bool,
}

impl XswdSessionRegistry {
    pub(super) fn register(
        &mut self,
        state: &Arc<AppState>,
    ) -> Result<u64, XswdSessionReferenceError> {
        let session_ref = self.project(state)?;
        self.sessions[&session_ref]
            .active
            .then_some(session_ref)
            .ok_or(XswdSessionReferenceError::Invalid)
    }

    pub(super) fn project(
        &mut self,
        state: &Arc<AppState>,
    ) -> Result<u64, XswdSessionReferenceError> {
        self.remove_dead();
        let state_ref = Arc::downgrade(state);
        if let Some((session_ref, _)) = self
            .sessions
            .iter()
            .find(|(_, registered)| Weak::ptr_eq(&registered.state, &state_ref))
        {
            return Ok(*session_ref);
        }

        let session_ref = NEXT_XSWD_SESSION_REFERENCE
            .fetch_update(Ordering::Relaxed, Ordering::Relaxed, |current| {
                current.checked_add(1)
            })
            .map_err(|_| XswdSessionReferenceError::Exhausted)?;
        self.sessions.insert(
            session_ref,
            XswdSessionEntry {
                state: state_ref,
                active: true,
            },
        );
        Ok(session_ref)
    }

    pub(super) fn resolve(&mut self, session_ref: u64) -> Option<Arc<AppState>> {
        self.remove_dead();
        self.sessions
            .get(&session_ref)
            .filter(|entry| entry.active)
            .and_then(|entry| Weak::upgrade(&entry.state))
    }

    pub(super) fn invalidate_state(&mut self, state: &Arc<AppState>) {
        self.remove_dead();
        let state_ref = Arc::downgrade(state);
        let mut found = false;
        for entry in self.sessions.values_mut() {
            if Weak::ptr_eq(&entry.state, &state_ref) {
                entry.active = false;
                found = true;
            }
        }
        if found {
            return;
        }

        // Disconnect can be the first event observed for a state. Preserve an
        // informational identity, but create it already inactive so a later
        // projection cannot mint fresh authority.
        if let Ok(session_ref) = NEXT_XSWD_SESSION_REFERENCE.fetch_update(
            Ordering::Relaxed,
            Ordering::Relaxed,
            |current| current.checked_add(1),
        ) {
            self.sessions.insert(
                session_ref,
                XswdSessionEntry {
                    state: state_ref,
                    active: false,
                },
            );
        }
    }

    pub(super) fn clear(&mut self) {
        self.remove_dead();
        for entry in self.sessions.values_mut() {
            entry.active = false;
        }
    }

    fn remove_dead(&mut self) {
        self.sessions
            .retain(|_, entry| entry.state.strong_count() > 0);
    }
}
