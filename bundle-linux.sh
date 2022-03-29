#!/usr/bin/env bash

set -euo pipefail

binary="$1"
out="$2"

bin_dir="bin"
lib_dir="lib"

mkdir -p "$out/$bin_dir" "$out/$lib_dir"

# Recursively bundle the given input executable or so
bundleBin() {
  local file="$1"
  local file_type="$2"

  local real_file
  real_file=$(realpath "$file")
  local install_dir="$out/$lib_dir"
  local rpath_prefix="\$ORIGIN"
  if [ "$file_type" = "exe" ]; then
    install_dir="$out/$bin_dir"
    rpath_prefix="\$ORIGIN/../$lib_dir"
  fi

  local file_name
  file_name=$(basename "$file")
  local real_file_name
  real_file_name=$(basename "$real_file")

  local copied_file
  copied_file="$install_dir/$real_file_name"

  local already_bundled="1"
  if [ ! -f "$copied_file" ]; then
    already_bundled="0"
    cp "$real_file" "$copied_file"
    chmod +w "$copied_file"
  fi

  if [ "$file_name" != "$real_file_name" ] && [ ! -f "$install_dir/$file_name" ]; then
    (cd "$install_dir" && ln -sf "$real_file_name" "$file_name")
    chmod +w "$install_dir/$file_name"
  fi

  if [ "$already_bundled" = "1" ]; then
    return
  fi

  echo "Bundling $real_file to $install_dir"

  local linked_libs
  linked_libs=$(ldd "$real_file" 2>/dev/null | grep -Eo '/nix/store/[^(=]+' || true)
  for linked_lib in $linked_libs; do
    bundleBin "$linked_lib" "lib"
  done

  patchelf --set-rpath "$rpath_prefix" "$copied_file"
}

bundleBin "$binary" "exe"
