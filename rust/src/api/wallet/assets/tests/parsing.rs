use super::*;

#[test]
fn asset_hash_defaults_to_xelis_and_accepts_custom_assets() {
    let custom = Hash::new([3; 32]);

    assert_eq!(resolve_asset_hash(None).unwrap(), XELIS_ASSET);
    assert_eq!(resolve_asset_hash(Some(&custom.to_hex())).unwrap(), custom);
}

#[test]
fn asset_hash_rejects_invalid_hex() {
    let error = resolve_asset_hash(Some("not-a-hash")).unwrap_err();

    assert!(error.to_string().starts_with("Invalid asset"));
}
