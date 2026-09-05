#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ! -f "$1" ]]; then
  echo "Usage: tool/check_android_16k.sh <release.apk>" >&2
  exit 64
fi

android_sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [[ -z "$android_sdk" || ! -d "$android_sdk" ]]; then
  echo "ANDROID_HOME or ANDROID_SDK_ROOT must identify the Android SDK." >&2
  exit 69
fi

zipalign="$(find -L "$android_sdk/build-tools" -type f \( -name zipalign -o -name zipalign.exe \) -perm -u+x -print | sort -V | tail -n 1)"
llvm_readelf="$(find -L "$android_sdk/ndk" -type f \( -path '*/bin/llvm-readelf' -o -path '*/bin/llvm-readelf.exe' \) -perm -u+x -print | sort -V | tail -n 1)"
if [[ -z "$zipalign" ]]; then
  echo "Could not locate zipalign under $android_sdk/build-tools." >&2
  exit 69
fi
if [[ -z "$llvm_readelf" ]]; then
  echo "Could not locate llvm-readelf under $android_sdk/ndk." >&2
  exit 69
fi

echo "Using zipalign: $zipalign"
echo "Using llvm-readelf: $llvm_readelf"

apk="$(realpath "$1")"
"$zipalign" -c -P 16 -v 4 "$apk"

extract_directory="$(mktemp -d)"
trap 'rm -rf -- "$extract_directory"' EXIT
unzip -q "$apk" 'lib/*/*.so' -d "$extract_directory"

mapfile -d '' libraries < <(find "$extract_directory/lib" -type f -name '*.so' -print0)
if [[ ${#libraries[@]} -eq 0 ]]; then
  echo "The APK does not contain any shared libraries." >&2
  exit 65
fi

checked_libraries=0
for library in "${libraries[@]}"; do
  abi="$(basename "$(dirname "$library")")"
  case "$abi" in
    arm64-v8a|x86_64) ;;
    armeabi-v7a|x86)
      # Android's 16 KB runtime requirement applies to 64-bit ABIs. A 4 KB
      # ARMv7 library does not make an otherwise aligned 64-bit APK invalid.
      echo "Skipping 32-bit ELF page-size check: $abi/$(basename "$library")"
      continue
      ;;
    *)
      echo "Unsupported Android ABI in $library: $abi" >&2
      exit 65
      ;;
  esac
  if ! elf_headers="$("$llvm_readelf" -lW "$library")"; then
    echo "Could not read ELF program headers in $library." >&2
    exit 65
  fi
  alignments="$(awk '$1 == "LOAD" { print $NF }' <<< "$elf_headers")"
  if [[ -z "$alignments" ]]; then
    echo "No ELF LOAD segments in $library." >&2
    exit 65
  fi
  while read -r alignment; do
    if [[ ! "$alignment" =~ ^0x[0-9a-fA-F]+$ ]]; then
      echo "Invalid ELF LOAD alignment in $library." >&2
      exit 65
    fi
    alignment_value=$((alignment))
    if (( alignment_value < 0x4000 )); then
      echo "ELF LOAD alignment below 16 KB in $library: $alignment" >&2
      exit 65
    fi
  done <<< "$alignments"
  checked_libraries=$((checked_libraries + 1))
done

if (( checked_libraries == 0 )); then
  echo "No supported 64-bit Android libraries were checked." >&2
  exit 65
fi

echo "Android ZIP and all $checked_libraries 64-bit ELF libraries are aligned for 16 KB pages. Runtime testing is still required."
