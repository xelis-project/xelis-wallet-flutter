# Native loading smoke consumer

This application verifies that a consuming Flutter project can build, bundle,
load, and call the Rust library exposed by `xelis_wallet_flutter`.

The smoke flow initializes the process-wide FRB runtime and validates a known
invalid address. It does not open a wallet, access wallet storage, or contact a
daemon.

Run the platform integration test with an available device, for example:

```shell
flutter test integration_test/native_library_smoke_test.dart -d windows
```
