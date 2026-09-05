# xelis-wallet-flutter agent guidance

## Scope

This repository owns the shared Flutter integration for the native XELIS
wallet runtime. Application state management and UI remain in consuming
Flutter applications.

## Documentation layers

- `README.md` is the consumer quick start: package scope, first integration,
  guide index, validation, and Web setup.
- `docs/*.md` describes current public contracts and consumer responsibilities
  by domain. Prefer links between guides over repeating cross-cutting rules.
- `AGENTS.md` is maintainer guidance for architecture, generation, compatibility,
  and validation. Internal implementation constraints belong here rather than in
  consumer examples.
- `CHANGELOG.md` summarizes released or unreleased public capabilities. It is
  not a construction log.

Keep public guides current-state focused. Historical implementation steps,
temporary migration notes, and consumer-specific application code do not belong
in the published documentation.

## Sources of truth

- Dart/Flutter dependencies: `pubspec.yaml`
- Rust dependencies and features: `rust/Cargo.toml`
- Authored bridge API: `rust/src/api/**`
- FRB configuration: `flutter_rust_bridge.yaml`
- Native build hook: `hook/build.dart`
- Reproducible Rust toolchain and targets: `rust/rust-toolchain.toml`
- Authored public Dart contracts: `lib/src/api/**`
- Private generated-to-public adapters: `lib/src/bridge/**`
- Public Dart runtime façade: `lib/src/runtime/xelis_wallet_flutter.dart`
- Error boundary and consumer guidance: `docs/error-handling.md`
- Lossless address and integrated-data contract: `docs/address-api.md`
- Destination-first address-book contract: `docs/address-book-api.md`
- Lossless wallet read and extra-data policy: `docs/wallet-read-api.md`
- Prepared transaction and broadcast contract: `docs/prepared-transactions.md`
- Runtime-event lifecycle and consumer guidance: `docs/runtime-events.md`
- Native logging policy and consumer guidance: `docs/logging.md`
- Multisig wire contract: `docs/multisig-signing-protocol.md`
- XSWD lifecycle, callbacks, and redaction contract: `docs/xswd-api.md`
- Core capability alignment matrix: `docs/upstream-compatibility.md`

## Generated files

Never edit these files manually:

- `lib/src/generated/rust_bridge/**`
- `rust/src/frb_generated.rs`

Regenerate them with `flutter_rust_bridge_codegen generate`.
Prefer `dart tool/generate_bindings.dart`, which bypasses package Native Asset
hooks until the bridge has been regenerated. It clears only the two known
generated output locations first so obsolete FRB files cannot survive a module
move, then regenerates the required Freezed parts. Do not use `dart run` for
this bootstrap script: stale or missing Rust bindings can otherwise prevent the
script itself from starting.

Native Android, iOS, Linux, macOS, and Windows builds use Flutter Native Assets.
Keep `hook/build.dart` pointed at the `rust` crate, keep
`flutter_rust_bridge_hooks` aligned exactly with FRB, and keep the concrete Rust
toolchain and supported target list in `rust/rust-toolchain.toml`. Do not
reintroduce a root `ffiPlugin` scaffold, platform build glue, or vendored
Cargokit. Web remains on the separate `wasm-pack` shared-memory pipeline.

The generated FRB entrypoint is private. Consumers initialize the package via
`XelisWalletFlutter` from `package:xelis_wallet_flutter/xelis_wallet_flutter.dart`.
Do not add public forwarding exports for `frb_generated.dart` or the generated
global lifecycle functions; expose lifecycle operations through the façade.
The root library must export authored contracts only. Do not add public
`lib/api/**` forwarders or other generated compatibility entrypoints.

## Compatibility rules

- Pin `xelis_wallet` and `xelis_common` to the same exact upstream revision.
  Update both revisions atomically after auditing the complete upstream diff;
  never mix floating branches, tags, or different revisions between them.
- Treat every public Rust API and forwarding Dart export as a cross-language
  contract.
- Keep `lib/src/api/**` independent from generated bindings and FRB packages;
  conversions between authored and generated types belong in `lib/src/bridge`.
- Stable root APIs must translate FRB failures to `XelisWalletException` while
  preserving the original stack trace. Unknown Dart exceptions remain
  unchanged. Diagnostic native messages are not inherently safe for UI or logs.
- Author every public `XelisWalletOperation` at the exact stable façade boundary
  and derive `XelisWalletErrorCode` only from typed native classification, an
  explicit package precondition, or a documented conservative adapter fallback.
  Consumers must not override package metadata, and adapters must never infer
  identifiers from exception prose. Reuse existing constants when semantics
  match; a new or renamed identifier is a public error contract change requiring
  documentation and focused mapping tests. Follow `docs/error-handling.md` for
  naming and fallback rules.
- A wrapper around a local RustOpaque handle may expose idempotent per-handle
  disposal and an authored use-after-dispose guard. Do not confuse this with
  terminal disposal of the process-wide FRB runtime.
- Never expose the generated wallet delegate. Route wallet lifecycle and every
  supported operation through the authored handle so wrapper state cannot
  diverge from the native wallet.
- Keep runtime initialization, XELIS configuration, logging, and the optional
  crypto provider as explicit façade operations; consumers own their ordering.
- Each native log or progress stream replaces a process-global sink. Consumers
  must create and retain only one stream subscription of each kind.
- Keep both wallet event channels pull-driven behind authored subscriptions. A
  subscription owns one immutable `u64` generation, a monotone `u64` sequence,
  one upstream receiver, and at most one in-flight native read. The runtime
  channel is connection-scoped; the business channel is session-scoped and
  remains active offline. Dart exposes every Rust `u64` as `BigInt`.
- Rotate wallet runtime subscriptions in this exact order: invalidate the old
  consumer generation, cancel and await the old subscription, await
  `setOffline`, create and listen to the new subscription, then call
  `setOnline`. Recheck wallet/session/request/generation after every asynchronous
  boundary in a consuming application.
- A native lag is a typed non-terminal degradation requiring one coalesced
  authoritative reconciliation. An active native-channel close is terminal and
  structured. Explicit cancellation is normal and must not mint or display a
  failure. Always cancel, await the polling loop, and only then dispose the
  opaque subscription handle.
- Never parse or display an upstream `SyncError` message. It remains privileged
  diagnostic data on a conservative `wallet.sync / operation.failed` failure;
  only a subsequent typed `Offline` controls reconnection.
- Keep transaction, balance, and asset events on the authored business channel.
  Never reintroduce the generated JSON event stream or depend on
  `xelis-dart-sdk` from this package. Never expose `PlaintextExtraData.shared_key`
  or arbitrary decrypted payloads through passive events.
- Keep every supported transaction amount and fee in atomic `u64`/Dart
  `BigInt` units. Never expose `double`, Rust `f64`, formatted coin strings, or
  JSON/SDK transaction builders on the authored preparation path. Fee boosts
  use checked basis-point arithmetic, and review always displays the fee from
  the exact prepared transaction rather than an earlier estimate. Redact both
  explicit and integrated extra-data payloads from prepared projections;
  project an integrated destination as its normal address plus presence and
  encryption metadata.
- Parse and create integrated addresses only through the authored
  `XelisAddressDescriptor`/`XelisDataElement` contract. Preserve data-value
  tags, exact unsigned widths, ordered non-string field keys, and immutable
  blob bytes. The private Rust wire carries unsigned values as canonical
  decimal strings so `u128` remains exact on Web. Never replace this contract
  with the upstream untagged JSON representation or a string-keyed Dart map.
- Store and send the complete canonical address-book destination. Derive the
  base address only for lookup; never deduplicate, copy, send, or substitute by
  base address. Treat exact, base-only, ambiguous, and absent matches as
  distinct exhaustive states. Keep legacy migration non-destructive and mark
  v2 complete only after every entry is durable.
- Keep metadata as the default for history and pending lists. Preserve a
  consumer's explicit redacted, metadata, or detailed disclosure through every
  read and business subscription; detailed payloads require an explicit
  detail, reveal, or diagnostic action.
- Pass a parsed `XelisAddressDescriptor` to history filters. Preserve standard
  counterparty semantics, but filter an integrated destination by exact base
  key plus canonical `DataElement` before pagination. For incoming history the
  destination is implicit and may match only when the integrated base is the
  current wallet. Never degrade an integrated filter to base-only matching or
  disclose its payload merely because it participates in native comparison.
- Reveal prepared attached data only through
  `inspectPreparedTransferExtraData()` with the exact authored prepared object
  and transfer index. Never reconstruct or bypass its wallet/generation/hash
  capability binding.
- Bind cancellation and broadcast to the exact authored prepared object, its
  originating wallet handle, native preparation generation, and canonical
  hash. A reconstructed, replaced, cross-wallet, or already-consumed object
  must fail closed. Reset application confirmation after every replacement and
  recheck wallet/session/object identity after asynchronous authentication.
- Preserve the prepared slot disposition in the five typed broadcast results:
  submitted consumes, retryable restores, rejected and local failure consume,
  and submitted-needs-resync consumes. Every non-clean result carries the
  original structured `XelisWalletException`; consumers record its existing
  XWF reference once and must not infer retry behavior from prose.
- Keep standard native logging allowlisted by the package-owned target and
  diagnostic logging allowlisted by package-owned module targets. Free-form
  dependency records never cross the bridge. Never log seeds, keys, passwords,
  tokens, signing material, or complete externally controlled payloads.
- Operational paths, amounts, balances, addresses, and hashes may be useful in
  an explicitly enabled local diagnostic workflow, but must not be retained or
  displayed by production defaults.
- Preserve native and web feature constraints.
- Treat multisig domains, envelope versions, and serialized field names as
  protocol constants. After v1 is published, incompatible changes require a
  new protocol version and explicit migration tests.
- Do not change wallet storage behavior, lifecycle ordering, error exposure,
  transaction review binding, or XSWD callbacks without focused tests and
  consumer validation.
- Preserve valid upstream capabilities unless the stable Flutter boundary
  requires a documented representation, lifecycle, or opt-in adaptation.
  Package safety defaults must not silently become application business rules.
- Keep `docs/upstream-compatibility.md` current when a public contract is
  exact, adapted, opt-in, intentionally unsupported, or leaves an upstream gap.
- Rename the native library only as an atomic Rust, FRB, platform, and consumer
  migration.
- Keep native build-backend migrations separate from public API changes.

## Validation

For Rust-only changes run `cargo fmt --check`, `cargo check --locked`, and
focused tests. For FFI changes regenerate bindings, run the Rust checks, then
run `dart analyze` and `flutter test`; the root suite includes a real host smoke
that loads and calls the Rust library. Use `tool/consumer_smoke.dart` for
release or manual consumer validation. It must generate outside the repository,
delete only its owned temporary directory, and keep `run` limited to desktop
targets plus the explicit headless Chrome Web consumer. The Web run must build
the resolved package's Rust/WASM bundle, build the release consumer, and execute
the initialization, integrated-address, and exact-integer smoke. It does not
replace an XSWD relay-to-review-to-decision end-to-end test. Validate every
supported native platform on an appropriate host;
Android release artifacts must retain 16 KB ZIP alignment and 16 KB ELF
alignment for every supported 64-bit ABI (ARM64 and x86_64). ARMv7 remains a
4 KB runtime target; do not misclassify its ELF alignment as a 64-bit failure.
Validate the alignment checker against malformed or unreadable ELF output as
well as aligned and unaligned libraries. Alignment does not replace execution
on a 16 KB Android environment. Run the
separate Web build during release or explicit manual validation.
