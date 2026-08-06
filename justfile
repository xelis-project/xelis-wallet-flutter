set windows-shell := ["cmd.exe", "/d", "/c"]

default:
    @just --list

alias gen := generate
alias validate := verify

# Fetch Dart and Flutter dependencies.
get:
    flutter pub get

# Regenerate FRB and Freezed outputs through the supported repository script.
generate:
    dart run tool/generate_bindings.dart

# Apply formatting to authored Rust and Dart sources.
format:
    cd rust && cargo fmt
    dart format lib test tool

# Fail when authored Rust or Dart sources need formatting.
format-check:
    cd rust && cargo fmt --check
    dart format --output=none --set-exit-if-changed lib test tool

# Fast Rust-only validation.
rust-check:
    cd rust && cargo check --locked

rust-test:
    cd rust && cargo test --locked

# Static analysis of the Flutter package.
analyze:
    dart analyze

# Fast cross-language validation without running tests.
check:
    just format-check
    just rust-check
    just analyze

# Run the complete Rust and Flutter test suites.
test:
    just rust-test
    flutter test

# Full validation used before handing off a change.
verify:
    just check
    just test

# Ensure the working tree has no whitespace errors.
diff-check:
    git diff --check

# Show the current branch and any local changes.
status:
    git status --short --branch

# Remove Flutter build outputs and generated local tool state.
clean:
    flutter clean

# Remove Rust build outputs (rust/target).
clean-rust:
    cd rust && cargo clean

# Remove both Flutter and Rust build outputs.
clean-all:
    just clean
    just clean-rust

# Build the intentionally uncommitted Web package for a consuming application.
build-web:
    dart run tool/build_web.dart --output web/pkg
