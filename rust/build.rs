fn main() {
    println!("cargo:rerun-if-changed=build.rs");
    let target = std::env::var("TARGET").expect("Cargo must provide TARGET");
    for argument in android_shared_library_link_args(&target) {
        println!("cargo:rustc-link-arg-cdylib={argument}");
    }
}

// Keep ELF alignment on the final XWF shared library, regardless of the
// consumer's working directory, Cargo rustflags, or NDK linker defaults.
// Do not apply Android linker options to host tools, static libraries or WASM.
fn android_shared_library_link_args(target: &str) -> &'static [&'static str] {
    match target {
        "aarch64-linux-android" | "x86_64-linux-android" => &[
            "-Wl,-z,max-page-size=16384",
            "-Wl,-z,common-page-size=16384",
        ],
        _ => &[],
    }
}

#[cfg(test)]
mod tests {
    use super::android_shared_library_link_args;

    #[test]
    fn android_64_bit_shared_libraries_require_16k_pages() {
        for target in ["aarch64-linux-android", "x86_64-linux-android"] {
            assert_eq!(
                android_shared_library_link_args(target),
                [
                    "-Wl,-z,max-page-size=16384",
                    "-Wl,-z,common-page-size=16384"
                ]
            );
        }
    }

    #[test]
    fn other_targets_do_not_receive_android_linker_flags() {
        for target in [
            "armv7-linux-androideabi",
            "i686-linux-android",
            "x86_64-unknown-linux-gnu",
            "x86_64-pc-windows-msvc",
            "aarch64-apple-darwin",
            "aarch64-apple-ios",
            "wasm32-unknown-unknown",
        ] {
            assert!(
                android_shared_library_link_args(target).is_empty(),
                "{target}"
            );
        }
    }
}
