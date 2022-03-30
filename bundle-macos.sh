#!/usr/bin/env bash

set -euo pipefail

out="$1"
binary="$2"

bin_dir="bin"
dylib_dir="Frameworks/Library.dylib"

mkdir -p "$out/$bin_dir" "$out/$dylib_dir"

bundleBin() {
  local file="$1"
  local file_type="$2"

  local real_file
  real_file=$(realpath "$file")
  local install_dir="$out/$dylib_dir"
  local rpath_prefix="@loader_path"
  if [ "$file_type" == "exe" ]; then
    install_dir="$out/$bin_dir"
    rpath_prefix="@executable_path/../$dylib_dir"
  fi

  local copied_file
  copied_file="$install_dir/$(basename "$real_file")"
  if [ -f "$copied_file" ]; then
    return
  fi

  echo "Bundling $real_file to $install_dir"
  cp "$real_file" "$copied_file"
  chmod +w "$copied_file"

  local linked_libs
  linked_libs=$(otool -L "$real_file" | tail -n +2 | grep '/nix/store/' | cut -d '(' -f -1 || true)
  for linked_lib in $linked_libs; do
    local real_lib
    real_lib=$(realpath "$linked_lib")
    local real_lib_name
    real_lib_name=$(basename "$real_lib")
    install_name_tool -change "$linked_lib" "$rpath_prefix/$real_lib_name" "$copied_file"
    bundleBin "$real_lib" "lib"
  done

  codesign -f -s - "$copied_file"
}

bundleBin "$binary" "exe"
find "$out/$bin_dir" -type f -executable -exec codesign -f -s - '{}' \;
