use super::*;

#[test]
fn csv_export_requires_at_least_one_transaction() {
    let error = ensure_transactions_to_export(0).unwrap_err();
    assert_eq!(error.source, NativeXelisErrorSource::XelisWalletFlutter);
    assert_eq!(error.code, NativeXelisErrorCode::NotFound);
    assert_eq!(
        error.native_kind.as_deref(),
        Some("WALLET_HISTORY_CSV_EMPTY")
    );
    assert!(!error.diagnostic_message.contains("history.csv"));
    assert!(ensure_transactions_to_export(1).is_ok());
}

#[cfg(not(target_arch = "wasm32"))]
#[test]
fn csv_destination_is_replaced_only_after_the_temporary_file_is_complete() {
    let directory = tempdir().unwrap();
    let destination = directory.path().join("history.csv");
    fs::write(&destination, "existing export").unwrap();

    let mut temporary = create_temporary_csv_file(&destination).unwrap();
    temporary.write_all(b"replacement export").unwrap();

    assert_eq!(fs::read_to_string(&destination).unwrap(), "existing export");

    persist_csv_file(temporary, &destination).unwrap();
    assert_eq!(
        fs::read_to_string(&destination).unwrap(),
        "replacement export"
    );
}

#[cfg(not(target_arch = "wasm32"))]
#[test]
fn csv_path_is_privileged_diagnostic_data_only() {
    let destination = Path::new(r"C:\private\wallet\history.csv");
    let error = csv_path_error(
        "access denied",
        destination,
        "WALLET_HISTORY_CSV_TEMP_FILE_CREATE_FAILED",
        "Unable to create the temporary CSV file",
    );

    assert_eq!(error.code, NativeXelisErrorCode::Storage);
    assert!(error
        .diagnostic_message
        .contains(destination.to_string_lossy().as_ref()));
    assert!(!error.to_string().contains("private"));
}
