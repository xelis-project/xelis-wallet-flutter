# Maintainer validation

This guide defines the validation evidence expected before publishing
`xelis-wallet-flutter`. Create a release tag only after reviewing the evidence
for the exact candidate commit.

## Local checks

After changing the Rust bridge surface, regenerate bindings before running the
package checks:

```text
flutter pub get
dart tool/generate_bindings.dart
dart format --output=none --set-exit-if-changed lib test tool bin hook
dart analyze
flutter test
cd rust
cargo fmt --check
cargo check --locked
cargo test --locked
```

`dart tool/generate_bindings.dart` is the supported generation path. It avoids
running Native Asset hooks against stale or missing generated Rust bindings.
Install the matching generator with
`cargo install flutter_rust_bridge_codegen --version 2.13.0 --locked`.
Never edit `lib/src/generated/rust_bridge/**` or
`rust/src/frb_generated.rs` manually.

`flutter test` includes a host smoke that initializes and calls the Rust
library. It is the lightweight pull-request boundary, not proof for every
supported platform.

## Real XSWD transport tests

Two Rust tests intentionally use production Argon2 work and real loopback
WebSocket transports. They remain ignored in the fast Rust suite and are run
serially by the Linux job in the tag/manual consumer workflow:

```text
cd rust
cargo test --locked --lib api::xswd::imp::tests::network::real_local_close_emits_cancel_and_disconnect_before_cleanup -- --ignored --exact --test-threads=1
cargo test --locked --lib api::xswd::imp::tests::network::real_relayer_close_stops_transport_while_disconnect_callback_is_pending -- --ignored --exact --test-threads=1
```

Each invocation must report exactly one passing test. A successful command
that selected zero tests is not evidence. Run them in series because the local
test uses the production XSWD port.

## Generated consumer matrix

`tool/consumer_smoke.dart` creates a clean Flutter application under the
system temporary directory and depends on the current package through a local
path. It deletes only its own direct temporary child unless `--keep` is set.

```text
dart --packages=.dart_tool/package_config.json tool/consumer_smoke.dart --platform linux --mode run
dart --packages=.dart_tool/package_config.json tool/consumer_smoke.dart --platform windows --mode run
dart --packages=.dart_tool/package_config.json tool/consumer_smoke.dart --platform macos --mode run
dart --packages=.dart_tool/package_config.json tool/consumer_smoke.dart --platform android --mode build
dart --packages=.dart_tool/package_config.json tool/consumer_smoke.dart --platform ios --mode build
dart --packages=.dart_tool/package_config.json tool/consumer_smoke.dart --platform web --mode run
```

`run` is supported for Linux, macOS, Windows, and Web. Mobile targets use a
release build. Validate each native platform on an appropriate host.

The Web run builds the resolved package's Rust/WASM bundle, builds a release
Flutter consumer, and launches headless Chrome. It verifies bridge
initialization and an integrated-address round trip containing `2^53 + 1` and
`u64::MAX`. It does not exercise the XSWD relay, permission review, decision
callbacks, durable browser storage, or network broadcast.

GitHub Actions runs the complete consumer matrix only for a release tag or an
explicit manual dispatch of **Consumer validation**. Ordinary pull requests do
not pay for this platform matrix.

## Android 16 KB pages

An Android release is accepted only when every supported 64-bit ABI has both
16 KB ZIP alignment and 16 KB ELF segment alignment:

```text
dart tool/test_android_16k.dart
bash tool/check_android_16k.sh <release.apk>
```

Run the checker on Linux, macOS, or Git Bash with `ANDROID_HOME` set. It must
reject unreadable and malformed ELF output as well as unaligned libraries.
ARM64 and x86_64 are 16 KB targets; ARMv7 remains a 4 KB runtime target and is
not a 64-bit alignment failure.

Passing the artifact checks does not replace installing and launching the
release consumer on a real or emulated 16 KB Android environment.

## Release evidence

Before creating a release tag, record the result of:

- Dart analysis, Flutter tests, and locked Rust checks;
- both real XSWD transport-close tests with one selected test each;
- Linux, Windows, macOS, Android, iOS, and Web consumer jobs;
- Android artifact alignment and 16 KB execution;
- Web release smoke under the hosting conditions in [the Web guide](web.md).

Successful commands prove only the paths they execute. Record skipped hosts,
unverified browser engines, unrelated failures, and residual upstream gaps.

## Publishing sequence

1. Commit the release documentation and verify that `pubspec.yaml`,
   `rust/Cargo.toml`, the changelog, and the README installation reference agree
   on the release version.
2. Push the reviewed branch and run **Pull request validation** and
   **Consumer validation** manually on that branch, selecting `all` for the
   consumer matrix. Verify that both runs tested the intended commit.
3. Review the results and the separate Android 16 KB execution evidence.
   The Android CI job builds and checks alignment; it does not launch an
   emulator. Resolve failed or missing required checks before tagging.
4. Create the annotated tag on that validated commit. For version 0.3.0:
   `git tag -a v0.3.0 <validated-commit> -m "Release 0.3.0"`.
5. Push that tag explicitly with `git push origin v0.3.0`. The tag triggers
   **Consumer validation** again; inspect its results before announcing release.

Tags are the Git installation boundary; this package is not published to
pub.dev (`publish_to: none`). Do not move an already published release tag.
