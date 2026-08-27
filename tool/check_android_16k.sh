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

zipalign="$(find "$android_sdk/build-tools" -type f -name zipalign -print | sort -V | tail -n 1)"
llvm_readelf="$(find "$android_sdk/ndk" -type f -path '*/bin/llvm-readelf' -print | sort -V | tail -n 1)"
if [[ -z "$zipalign" || -z "$llvm_readelf" ]]; then
  echo "Could not locate zipalign and llvm-readelf in the Android SDK." >&2
  exit 69
fi

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

for library in "${libraries[@]}"; do
  while read -r alignment; do
    alignment_value=$((alignment))
    if (( alignment_value < 0x4000 )); then
      echo "ELF LOAD alignment below 16 KB in $library: $alignment" >&2
      exit 65
    fi
  done < <("$llvm_readelf" -lW "$library" | awk '$1 == "LOAD" { print $NF }')
done

echo "Android ZIP and ELF alignment are compatible with 16 KB pages."
