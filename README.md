# xelis-wallet-flutter

Shared Flutter integration for the native XELIS wallet runtime.

The package owns the consumer-independent Rust and Dart boundary used by
Flutter wallet applications. Application state management, presentation,
localized messages, retry policy, and diagnostic retention remain the
responsibility of the consuming application.

The repository is licensed under GPL-3.0-only. The vendored Cargokit build
tooling retains its MIT/Apache-2.0 licensing under `cargokit/LICENSE`.

## Add the package

Add the current release to the consuming Flutter application's `pubspec.yaml`:

```yaml
dependencies:
  xelis_wallet_flutter:
    git:
      url: https://github.com/xelis-project/xelis-wallet-flutter.git
      ref: v0.1.1
```

Keep `ref` pinned to a release tag. Update it when adopting a new package
release, then run `flutter pub get` in the consuming application.

### Requirements

The consuming application needs Dart 3.10 or later and Flutter 3.38.1 or
later. Native targets compile the bundled Rust runtime, so a Rust/Cargo
toolchain is also required on build machines.

| Target | Consumer requirement |
| --- | --- |
| Android | `compileSdk` 36, `minSdk` 24, Java 17, and an Android NDK configured for the Flutter application |
| iOS | iOS 11 or later and the normal Xcode/CocoaPods toolchain |
| Linux, macOS, Windows | The normal Flutter desktop toolchain plus Rust/Cargo |
| Web | The separate Web build described below; it needs `wasm-pack`, Rust `nightly`, and the WebAssembly target |

The native Flutter plugin supports Android, iOS, Linux, macOS, and Windows.
Web uses the dedicated shared-memory WASM build pipeline.

Consumers must import only the root library:

```dart
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';
```

The generated Flutter Rust Bridge surface under `lib/src/generated` is private.
The root library exports authored Dart contracts and the stable
`XelisWalletFlutter` façade only.

## Initialize the runtime

Runtime, logging, XELIS configuration, and the optional crypto provider are
explicit operations so applications can control their startup order:

```dart
Future<void> initializeXelisWallet() async {
  await XelisWalletFlutter.initialize();
  await XelisWalletFlutter.initializeConfiguration();

  // Optional: configure native logging once for the process.
  // await XelisWalletFlutter.initializeRustLogger();

  // Enable only when required by the consuming application.
  // await XelisWalletFlutter.initializeCryptoProvider();
}
```

Initialization is idempotent and concurrent calls are shared. Native log and
progress streams each replace one process-global sink, so retain at most one
subscription of each kind.

## Open and close a wallet

Wallet creation, recovery, and opening return an authored `XelisWallet` handle.
Passwords, seeds, and private keys pass directly to Rust and are not persisted
or logged by the Dart façade.

```dart
XelisWallet? wallet;
try {
  wallet = await XelisWalletFlutter.openWallet(
    walletPath: walletPath,
    password: password,
    network: XelisNetwork.mainnet,
    precomputedTableType: const XelisPrecomputedTableType.l1Low(),
  );

  await wallet.setOnline(daemonAddress: daemonAddress);
  final balance = await wallet.getXelisBalance();
  // Project `balance` in application state.
} finally {
  final handle = wallet;
  if (handle != null) {
    try {
      await handle.close();
    } finally {
      handle.dispose();
    }
  }
}
```

`close()` is terminal, idempotent, and coalesces concurrent calls. `dispose()`
releases the local opaque handle after the close attempt completes. It does not
dispose the process-wide runtime.

`changePassword()` updates the native wallet only. An application that stores a
separate biometric credential must update it after native success and define a
compensation path if that persistence fails.

Create runtime subscriptions before calling `setOnline()`, and keep business
subscriptions for the whole opened-wallet session. Follow the cancellation and
connection-rotation order in the runtime-events guide.

## Documentation

| Level | Audience and purpose |
| --- | --- |
| This README | Consumers evaluating the package or completing their first integration |
| [`docs/`](docs/) API guides | Flutter application developers implementing one public contract |
| [`AGENTS.md`](AGENTS.md) | Package maintainers and coding agents preserving internal invariants |

The README is intentionally a quick start. Public behavior and consumer rules
belong in the domain guides; implementation and maintenance constraints belong
in `AGENTS.md` and must not be presented as consumer API.

### API guides

| Topic | Guide |
| --- | --- |
| Structured failures, support IDs, and consumer handling | [`docs/error-handling.md`](docs/error-handling.md) |
| Standard and integrated addresses | [`docs/address-api.md`](docs/address-api.md) |
| Destination-first address book | [`docs/address-book-api.md`](docs/address-book-api.md) |
| Balances, assets, history, and explicit extra-data reads | [`docs/wallet-read-api.md`](docs/wallet-read-api.md) |
| Transaction preparation, review, cancellation, and broadcast | [`docs/prepared-transactions.md`](docs/prepared-transactions.md) |
| Runtime and business event subscriptions | [`docs/runtime-events.md`](docs/runtime-events.md) |
| Native standard and diagnostic logging | [`docs/logging.md`](docs/logging.md) |
| Multisig request and signature-share wire protocol | [`docs/multisig-signing-protocol.md`](docs/multisig-signing-protocol.md) |
| XSWD lifecycle, callbacks, relayers, and redaction | [`docs/xswd-api.md`](docs/xswd-api.md) |

The façade also exposes seed dictionary search, address validation and parsing,
integrated-address creation, and precomputed-table helpers. Integrated address
data is public protocol data and must never contain wallet secrets or
authentication material.

Every Rust `u64` exposed by package-owned public models uses Dart `BigInt` so
amounts, balances, generations, and sequence numbers remain lossless on native
and Web targets.

Stable package failures use `XelisWalletException`. Applications should record
its safe structured metadata once, map its stable code to localized copy, and
never display or parse `diagnosticMessage`.

## Maintainer validation

After changing the Rust bridge API, package maintainers regenerate bindings and
run:

```text
flutter pub get
dart run tool/generate_bindings.dart
dart analyze
flutter test
cd rust
cargo fmt --check
cargo check --locked
cargo test --locked
```

`dart run tool/generate_bindings.dart` is the supported generation path. Do not
edit `lib/src/generated/rust_bridge/**` or `rust/src/frb_generated.rs` manually.

## Web consumers

The generated Web package is intentionally not committed. Build it directly in
the consuming Flutter application's `web/pkg` directory:

```text
dart run ../xelis-wallet-flutter/tool/build_web.dart --output web/pkg
```

The Web host must enable cross-origin isolation for the shared-memory WASM
runtime. For local Flutter development:

```text
flutter run -d chrome --web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp
```

Production hosting must provide equivalent
`Cross-Origin-Opener-Policy: same-origin` and
`Cross-Origin-Embedder-Policy: require-corp` headers.
