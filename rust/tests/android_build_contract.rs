// Cargo does not run build-script unit tests by default. Include the exact
// script here so the normal locked Rust suite protects its target selection.
#[allow(dead_code)]
#[path = "../build.rs"]
mod build_script;
