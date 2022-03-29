# nix-bundle-exe

Simple bundler derivation to bundle binary executables built with [Nix](https://nixos.org/) into a relocatable directory structure. The result of this bundler can then be zipped or turned into a self-extracting archive for further distribution.

This tool currently supports macOS and Linux.

Some advantages of this approach:
  * Works on macOS
  * Has minimal build-time dependencies
  * Provides bundles that do not need the target OS to have specific features

## Example

This will make a bundle of `opencv` where all of its binaries can be run on a system where Nix is not installed.
```shell
nix-build -E 'with import <nixpkgs> {}; callPackage ./. {} opencv'
```
