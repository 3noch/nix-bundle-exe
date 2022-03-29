{ pkgs }:
if pkgs.stdenv.isDarwin then pkgs.callPackage ./bundle-macos.nix {}
else if pkgs.stdenv.isLinux then pkgs.callPackage ./bundle-linux.nix {}
else throw "Unsupported platform: only darwin and linux are supported"
