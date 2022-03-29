{ pkgs }:
pkg:
pkgs.runCommand "bundle-${pkg.name}" {
  nativeBuildInputs = with pkgs; [ coreutils which glibc ]; #darwin.binutils darwin.sigtool ];
} ''
  find '${pkg}/bin' -type f -executable -exec bash '${./bundle-linux.sh}' '{}' "$out" \;
''
