{ pkgs }:
pkg:
pkgs.runCommand "bundle-${pkg.name}" {
  nativeBuildInputs = with pkgs; [ coreutils glibc ];
} ''
  find '${pkg}/bin' -type f -executable -print0 | xargs -0 --max-args 1 bash '${./bundle-linux.sh}' "$out"
''
