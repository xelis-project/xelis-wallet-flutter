set windows-shell := ["cmd.exe", "/d", "/c"]

get:
    flutter pub get

generate:
    dart run tool/generate_bindings.dart

format:
    cd rust && cargo fmt
    dart format lib test tool

check:
    cd rust && cargo check --locked
    dart analyze

test:
    cd rust && cargo test --locked
    flutter test

build-web:
    dart run tool/build_web.dart
