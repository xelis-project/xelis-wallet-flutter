use super::*;

#[tokio::test]
async fn asset_resolution_returns_cache_without_daemon_or_persistence() {
    let cached = test_asset("Cached Token", "CACHE");
    let source = FakeAssetDataSource::new(CacheOutcome::Hit(cached), DaemonOutcome::Error, false);

    let result = source.resolve().await.unwrap();

    assert_eq!(result.get_ticker(), "CACHE");
    assert_eq!(*source.events.lock(), vec!["cache"]);
    assert!(source.persisted.lock().is_none());
}

#[tokio::test]
async fn asset_resolution_fetches_cache_miss_then_persists_daemon_result() {
    let fetched = test_asset("Remote Token", "REMOTE");
    let source =
        FakeAssetDataSource::new(CacheOutcome::Miss, DaemonOutcome::Success(fetched), false);

    let result = source.resolve().await.unwrap();

    assert_eq!(result.get_ticker(), "REMOTE");
    assert_eq!(
        *source.events.lock(),
        vec!["cache", "cache", "daemon", "persist"]
    );
    assert_eq!(
        source.persisted.lock().as_ref().map(AssetData::get_ticker),
        Some("REMOTE")
    );

    let cached_result = source.resolve().await.unwrap();

    assert_eq!(cached_result.get_ticker(), "REMOTE");
    assert_eq!(
        *source.events.lock(),
        vec!["cache", "cache", "daemon", "persist", "cache"]
    );
}

#[tokio::test]
async fn asset_resolution_stops_when_cache_read_fails() {
    let source = FakeAssetDataSource::new(CacheOutcome::Error, DaemonOutcome::Error, false);

    let error = source.resolve().await.unwrap_err();

    assert_eq!(error.to_string(), "cache failure");
    assert_eq!(*source.events.lock(), vec!["cache"]);
    assert!(source.persisted.lock().is_none());
}

#[tokio::test]
async fn asset_resolution_does_not_persist_a_daemon_failure() {
    let source = FakeAssetDataSource::new(CacheOutcome::Miss, DaemonOutcome::Error, false);

    let error = source.resolve().await.unwrap_err();

    assert_eq!(error.to_string(), "daemon failure");
    assert_eq!(*source.events.lock(), vec!["cache", "cache", "daemon"]);
    assert!(source.persisted.lock().is_none());
}

#[tokio::test]
async fn asset_resolution_reports_persistence_failure_after_fetch() {
    let fetched = test_asset("Remote Token", "REMOTE");
    let source =
        FakeAssetDataSource::new(CacheOutcome::Miss, DaemonOutcome::Success(fetched), true);

    let error = source.resolve().await.unwrap_err();

    assert_eq!(error.to_string(), "persistence failure");
    assert_eq!(
        *source.events.lock(),
        vec!["cache", "cache", "daemon", "persist"]
    );
    assert!(source.persisted.lock().is_none());
}

#[tokio::test]
async fn concurrent_asset_resolution_fetches_and_persists_only_once() {
    let fetched = test_asset("Remote Token", "REMOTE");
    let source =
        FakeAssetDataSource::new(CacheOutcome::Miss, DaemonOutcome::Success(fetched), false);

    let (first, second) = tokio::join!(source.resolve(), source.resolve());

    assert_eq!(first.unwrap().get_ticker(), "REMOTE");
    assert_eq!(second.unwrap().get_ticker(), "REMOTE");

    let events = source.events.lock();
    assert_eq!(events.iter().filter(|event| **event == "daemon").count(), 1);
    assert_eq!(
        events.iter().filter(|event| **event == "persist").count(),
        1
    );
}
