# Web integration

XWF Web combines two outputs in one browser application:

1. Flutter compiles the Dart application with its default JavaScript Web
   pipeline.
2. XWF compiles the Rust wallet runtime to shared-memory WebAssembly (WASM).
3. Flutter Rust Bridge connects the Dart application to that Rust/WASM module.

The generated Rust/WASM package is a build artifact and is not committed.

## Build

Install `wasm-pack`, Rust `nightly`, `rust-src`, and the WebAssembly target:

```text
cargo install wasm-pack --locked
rustup toolchain install nightly --profile minimal
rustup component add rust-src --toolchain nightly
rustup target add wasm32-unknown-unknown --toolchain nightly
```

From the consuming Flutter application's root, build the Rust package resolved
by Pub directly into the application's Web assets, then build Flutter:

```text
dart run xelis_wallet_flutter:build_web --output web/pkg
flutter build web
```

This validates Flutter's default JavaScript output with a Rust/WASM wallet. It
does not establish support for Flutter's separate Dart-to-Wasm mode
(`flutter build web --wasm`). With the pinned Flutter Rust Bridge 2.13.0, that
mode remains unverified and its dry run reports a JS-interop runtime-check
incompatibility.

## Cross-origin isolation

Shared WebAssembly memory requires a cross-origin-isolated page. The server
must return these headers for the application and its assets:

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

For local Flutter development:

```text
flutter run -d chrome --web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp
```

Apply equivalent headers in production and verify that the page reports
`crossOriginIsolated == true`. Cross-origin fonts, scripts, images, workers,
iframes, and popup integrations may need compatible CORS or resource-policy
headers. Test the deployed origin rather than assuming local-server success
transfers to production.

## Browser storage

In the locked XELIS core revision, the Web storage backend:

- holds the working database in memory;
- reloads a base64-encoded database from browser `localStorage` when opened;
- serializes the database back to `localStorage` when it is flushed.

The browser owns the availability and durability of that storage. It is scoped
to the site's origin; changing scheme, hostname, or port selects a different
storage area. Clearing site data, private browsing, storage policies, or quota
failures can make the saved wallet unavailable. Applications must surface
storage failures and must not describe browser storage as equivalent to a
native filesystem backup.

The release smoke currently verifies initialization and an exact data round
trip in one Chrome session. It does not prove reopen-after-browser-restart,
quota exhaustion, private-mode durability, eviction behavior, backup recovery,
or concurrent access from multiple tabs.

## XSWD and browser scope

Web consumers use relayer connections. They do not host the native local XSWD
WebSocket server. XWF preserves exact `u64` request values as Dart `BigInt` and
the same opaque session identity contract on Web, but relayer transport and
permission behavior remain subject to the guarantees and upstream limitation
documented in [the XSWD guide](xswd-api.md).

## Current validation boundary

The maintained Web consumer smoke uses headless Chrome and proves:

- the Rust/WASM package builds and loads;
- the authored root API initializes the bridge;
- an integrated address survives a Rust round trip;
- `2^53 + 1` and `u64::MAX` remain exact.

It is not a compatibility matrix for Firefox, Safari, Chromium mobile, or Web
views, and it does not prove transaction broadcast or long-running performance.
Qualify those environments separately before claiming support for them. See
[maintainer validation](validation.md) for the release command and evidence.
