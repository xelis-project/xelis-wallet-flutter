use super::*;

#[test]
fn asset_metadata_projects_every_field_losslessly() {
    let origin = Hash::new([1; 32]);
    let owner = Hash::new([2; 32]);
    let data = AssetData::new(
        8,
        "Example Token".to_owned(),
        "EXT".to_owned(),
        MaxSupplyMode::Mintable(1_000_000),
        AssetOwner::Owner {
            origin: origin.clone(),
            origin_id: 7,
            owner: owner.clone(),
        },
    );

    let metadata = asset_metadata(&data);

    assert_eq!(metadata.name, "Example Token");
    assert_eq!(metadata.ticker, "EXT");
    assert_eq!(metadata.decimals, 8);
    assert!(matches!(
        metadata.max_supply,
        XelisMaxSupplyMode::Mintable(1_000_000)
    ));
    assert!(matches!(
        metadata.owner,
        XelisAssetOwner::Owner {
            origin: mapped_origin,
            origin_id: 7,
            owner: mapped_owner,
        } if mapped_origin == origin.to_hex() && mapped_owner == owner.to_hex()
    ));
}

#[test]
fn asset_metadata_projects_absent_owner_and_fixed_supply() {
    let data = AssetData::new(
        0,
        "Fixed".to_owned(),
        "FIX".to_owned(),
        MaxSupplyMode::Fixed(42),
        AssetOwner::None,
    );

    let metadata = asset_metadata(&data);

    assert!(matches!(metadata.max_supply, XelisMaxSupplyMode::Fixed(42)));
    assert!(matches!(metadata.owner, XelisAssetOwner::None));
}
