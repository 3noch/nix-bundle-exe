{ pkgs }:
pkg:
pkgs.runCommand "bundle-${pkg.name}" {
  nativeBuildInputs = with pkgs; [ coreutils which darwin.binutils darwin.sigtool ];
} ''
  find '${pkg}/bin' -type f -executable -exec bash '${./bundle-macos.sh}' '{}' "$out" \;
''
