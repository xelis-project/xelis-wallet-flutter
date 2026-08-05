use flutter_rust_bridge::frb;

use std::ops::ControlFlow;

use anyhow::{bail, Result};
use log::trace;
use serde::{Deserialize, Serialize};
use xelis_common::crypto::ecdlp;
use xelis_wallet::precomputed_tables;

use crate::api::error::{NativeXelisError, NativeXelisErrorCode};
use crate::api::progress_report::{add_progress_report, ProgressReport};

#[frb]
#[derive(Serialize, Deserialize, Debug, Clone)]
pub enum PrecomputedTableType {
    L1Low,
    L1Medium,
    L1Full,
    Custom(usize),
}

impl PrecomputedTableType {
    /// Convert to the actual L1 size used by the tables code.
    /// For Custom(n), this enforces 16 <= n <= 32.
    pub fn to_l1_size(&self) -> Result<usize> {
        match *self {
            PrecomputedTableType::L1Low => Ok(precomputed_tables::L1_LOW),
            PrecomputedTableType::L1Medium => Ok(precomputed_tables::L1_MEDIUM),
            PrecomputedTableType::L1Full => Ok(precomputed_tables::L1_FULL),
            PrecomputedTableType::Custom(size) => {
                if size < 16 || size >= 33 {
                    bail!("Invalid custom L1 size: {} (must be 16..33)", size);
                }
                Ok(size)
            }
        }
    }

    // Custom(_) variant forces a sealed class instead of a Dart enum, so adding generic helper maps
    pub fn name(&self) -> String {
        match self {
            PrecomputedTableType::L1Low => "l1Low".to_string(),
            PrecomputedTableType::L1Medium => "l1Medium".to_string(),
            PrecomputedTableType::L1Full => "l1Full".to_string(),
            PrecomputedTableType::Custom(n) => format!("custom({})", n),
        }
    }

    pub fn index(&self) -> u32 {
        match self {
            PrecomputedTableType::L1Low => 0,
            PrecomputedTableType::L1Medium => 1,
            PrecomputedTableType::L1Full => 2,
            PrecomputedTableType::Custom(_) => 3,
        }
    }
}

pub struct LogProgressTableGenerationReportFunction;

impl ecdlp::ProgressTableGenerationReportFunction for LogProgressTableGenerationReportFunction {
    fn report(&self, progress: f64, step: ecdlp::ReportStep) -> ControlFlow<()> {
        let step_str = format!("{:?}", step);
        add_progress_report(ProgressReport {
            progress,
            step: step_str,
            message: None,
        });
        trace!("Progress: {:.2}% on step {:?}", progress * 100.0, step);

        ControlFlow::Continue(())
    }
}

pub async fn are_precomputed_tables_available(
    precomputed_tables_path: String,
    precomputed_table_type: PrecomputedTableType,
) -> std::result::Result<bool, NativeXelisError> {
    let size = precomputed_table_type.to_l1_size().map_err(|error| {
        NativeXelisError::xelis_wallet_flutter(
            NativeXelisErrorCode::InvalidInput,
            "PRECOMPUTED_TABLE_TYPE_INVALID",
            format!("{error:#}"),
        )
    })?;

    precomputed_tables::has_precomputed_tables(Some(precomputed_tables_path.as_str()), size)
        .await
        .map_err(|error| {
            NativeXelisError::from_wallet_operation(
                error,
                NativeXelisErrorCode::Storage,
                "PRECOMPUTED_TABLES_CHECK_FAILED",
            )
        })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn custom_table_size_accepts_the_stable_boundaries() {
        assert_eq!(PrecomputedTableType::Custom(16).to_l1_size().unwrap(), 16);
        assert_eq!(PrecomputedTableType::Custom(32).to_l1_size().unwrap(), 32);
    }

    #[test]
    fn custom_table_size_rejects_values_outside_the_stable_boundaries() {
        assert!(PrecomputedTableType::Custom(15).to_l1_size().is_err());
        assert!(PrecomputedTableType::Custom(33).to_l1_size().is_err());
    }
}
