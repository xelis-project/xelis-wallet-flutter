# xelis-wallet-flutter

Shared Flutter integration for the native XELIS wallet runtime.

The package owns the consumer-independent Rust and Dart boundary used by
Flutter wallet applications. Application state management, presentation,
localized messages, retry policy, and diagnostic retention remain the
responsibility of the consuming application.

The repository is licensed under GPL-3.0-only.

## Add the package

Add the current release to the consuming Flutter application's `pubspec.yaml`:

```yaml
dependencies:
  xelis_wallet_flutter:
    git:
      url: https://github.com/xelis-project/xelis-wallet-flutter.git
      ref: v0.3.0
```

Keep `ref` pinned to a release tag. Update it when adopting a new package
release, then run `flutter pub get` in the consuming application.

### Requirements

The consuming application needs Dart 3.13 or later and Flutter 3.47 or later.
Native targets compile the bundled Rust runtime through Flutter Native Assets,
so build machines must install Rustup. The package pins Rust 1.94.1 and its
supported targets in `rust/rust-toolchain.toml`; Rustup installs those exact
components for reproducible builds.

| Target | Consumer requirement |
| --- | --- |
| Android | `minSdk` 24, the normal Flutter 3.47 Android toolchain, AGP 8.5.1 or later, and NDK r28 or later for 16 KB page support |
| iOS | iOS 13 or later, Rustup, and the normal Xcode toolchain |
| Linux, macOS, Windows | macOS 10.15 or later where applicable, Rustup, and the normal Flutter desktop toolchain |
| Web | The separate Web build described below; it needs `wasm-pack`, Rust `nightly`, and the WebAssembly target |

The Native Assets build hook supports Android, iOS, Linux, macOS, and Windows.
Flutter invokes it automatically for native `run`, `build`, and `test`
commands. Web keeps the dedicated shared-memory WASM build pipeline described
below; the native hook does not replace it.

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
| Adaptation status versus the locked XELIS core | [`docs/upstream-compatibility.md`](docs/upstream-compatibility.md) |

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

Validation is split so pull requests pay for only one Native Assets Flutter
build. After changing the Rust bridge API, package maintainers regenerate
bindings and run the host checks:

```text
flutter pub get
dart tool/generate_bindings.dart
dart analyze
flutter test
cd rust
cargo fmt --check
cargo check --locked
cargo test --locked
```

`dart tool/generate_bindings.dart` is the supported generation path. Direct
script execution deliberately avoids running Native Asset hooks against stale
or missing generated Rust bindings before the generator can start. Do not
edit `lib/src/generated/rust_bridge/**` or `rust/src/frb_generated.rs` manually.
`hook/build.dart` is the authored Native Assets entrypoint and must keep its
crate path set to `rust`.

`flutter test` includes a host smoke that initializes and calls the Rust
library. It is the lightweight pull-request boundary. Release and manual
validation generate a clean consumer outside the repository:

```text
dart --packages=.dart_tool/package_config.json tool/consumer_smoke.dart --platform windows --mode run
dart --packages=.dart_tool/package_config.json tool/consumer_smoke.dart --platform web --mode run
dart --packages=.dart_tool/package_config.json tool/consumer_smoke.dart --platform android --mode build
```

`run` is available for Linux, macOS, Windows, and Web. The Web run builds the
resolved package's Rust/WASM bundle into a generated Flutter consumer, builds
that application in release mode, then uses headless Chrome to verify bridge
initialization and an integrated-address round trip containing `2^53 + 1` and
`u64::MAX`. This smoke does not exercise the XSWD relay, permission review, or
decision callbacks. Mobile consumers are built in release mode; Android release
validation must additionally check ZIP alignment and the ELF alignment of every
ARM64 and x86_64 library for 16 KB pages. ARMv7 remains a 4 KB runtime target.
Run `bash tool/check_android_16k.sh <release.apk>` on Linux/macOS or Git Bash
with `ANDROID_HOME` set. The checker rejects unreadable or malformed ELF
headers; its hermetic fixtures run with `dart tool/test_android_16k.dart`.
Passing alignment checks does not replace execution on a 16 KB device/emulator.
The consumer matrix pins Flutter 3.47.1. The
generated workspace is deleted unless `--keep` is provided. GitHub Actions runs
the full native and Web consumer matrix only for release tags or an explicit
manual dispatch.

## Web consumers

The generated Web package is intentionally not committed. From the consuming
Flutter application's root, build the Rust code bundled with the XWF revision
resolved by Pub directly into the application's `web/pkg` directory:

```text
dart run xelis_wallet_flutter:build_web --output web/pkg
```

The build requires `wasm-pack`, Rust `nightly`, and the
`wasm32-unknown-unknown` target. A typical rustup setup is:

```text
cargo install wasm-pack
rustup toolchain install nightly
rustup component add rust-src --toolchain nightly
rustup target add wasm32-unknown-unknown --toolchain nightly
```

Use Flutter's default JavaScript Web build (`flutter build web`) with this
Rust/WASM bundle. Flutter's separate Dart-to-Wasm mode (`--wasm`) is not
validated with the pinned FRB 2.13.0; its Wasm dry run reports a JS-interop
runtime-check incompatibility. A passing Rust/WASM consumer does not establish
support for that separate Flutter compilation mode.

The Web host must enable cross-origin isolation for the shared-memory WASM
runtime. For local Flutter development:

```text
flutter run -d chrome --web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp
```

Production hosting must provide equivalent
`Cross-Origin-Opener-Policy: same-origin` and
`Cross-Origin-Embedder-Policy: require-corp` headers.
