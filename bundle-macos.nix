{ pkgs }:
pkg:
pkgs.runCommand "bundle-${pkg.name}" {
  nativeBuildInputs = with pkgs; [ coreutils darwin.binutils darwin.sigtool ];
} ''
  find '${pkg}/bin' -type f -executable -print0 | xargs -0 --max-args 1 bash '${./bundle-macos.sh}' "$out"
''
