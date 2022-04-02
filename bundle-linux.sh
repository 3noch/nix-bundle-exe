#!/usr/bin/env bash

set -euo pipefail

out="$1"
binary="$2"

exe_dir="exe"
bin_dir="bin"
lib_dir="lib"

bundleLib() {
  local file="$1"
  local install_dir="$out/$lib_dir"

  local real_file
  real_file=$(realpath "$file")

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
    bundleLib "$linked_lib" "lib"
  done

  if [ -n "$linked_libs" ]; then
    patchelf --set-rpath "\$ORIGIN" "$copied_file"
  fi
}

bundleExe() {
  local exe="$1"
  local interpreter="$2"
  local exe_name
  exe_name=$(basename "$exe")
  local real_interpreter
  real_interpreter=$(realpath "$interpreter")
  local interpreter_checksum
  interpreter_checksum=$(sha256sum "$real_interpreter" | cut -d' ' -f1)
  local interpreter_install_path
  interpreter_install_path="/tmp/$interpreter_checksum-$(basename "$real_interpreter")"

  local copied_exe="$out/$exe_dir/$exe_name"
  cp "$exe" "$copied_exe"
  chmod +w "$copied_exe"
  patchelf --set-interpreter "$interpreter_install_path" --set-rpath "\$ORIGIN/../$lib_dir" "$copied_exe"

  bundleLib "$interpreter" "lib"

  local linked_libs
  linked_libs=$(ldd "$exe" 2>/dev/null | grep -Eo '/nix/store/[^(=]+' || true)
  for linked_lib in $linked_libs; do
    bundleLib "$linked_lib" "lib"
  done

  printf '#!/bin/sh
set -eu
dir="$(cd -- "$(dirname "$(dirname "$0")")" >/dev/null 2>&1 ; pwd -P)"
if [ ! -f %s ]; then
  cp "$dir"/%s %s
  chmod 555 %s
fi
exec "$dir"/%s "$@"' \
  "'$interpreter_install_path'" \
  "'$lib_dir/$(basename "$interpreter")'" \
  "'$interpreter_install_path'" \
  "'$interpreter_install_path'" \
  "'$exe_dir/$exe_name'" \
  > "$out/$bin_dir/$exe_name"
  chmod +x "$out/$bin_dir/$exe_name"
}

exe_interpreter=$(patchelf --print-interpreter "$binary" 2>/dev/null || true)
if [ -n "$exe_interpreter" ]; then
  mkdir -p "$out/$exe_dir" "$out/$bin_dir" "$out/$lib_dir"
  bundleExe "$binary" "$exe_interpreter"
else
  mkdir -p "$out/$bin_dir"
  cp "$binary" "$out/$bin_dir"
fi
