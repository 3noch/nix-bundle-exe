{ lib
, writeScriptBin
, buildPackages
, stdenv
, glibc
, runCommand
, nukeReferences
, bin_dir ? "bin"
, exe_dir ? "exe"
, lib_dir ? if stdenv.isDarwin then "Frameworks/Library.dylib" else "lib"
}:
path:
# May be:
#  1) a derivation,
#  2) a path to a directory containing bin/, or
#  3) a path to an executable.
let
  print-needed-elf = writeScriptBin
    "print-needed-elf"
    '''${buildPackages.python3}'/bin/python ${./print_needed_elf.py} "$@"'';

  cfg =
    if stdenv.isDarwin then
      {
        deps = with buildPackages; [ darwin.binutils darwin.sigtool ];
        script = "bash ${./bundle-macos.sh}";
      }
    else if stdenv.isLinux then
      {
        deps = [ glibc print-needed-elf ];
        script = "bash ${./bundle-linux.sh}";
      }
    else
      throw "Unsupported platform: only darwin and linux are supported";

  name = if lib.isDerivation path then path.name else builtins.baseNameOf path;
  overrideEnv = name: value: if value == null then "" else "export ${name}='${value}'";
in
runCommand "bundle-${name}"
{
  nativeBuildInputs = cfg.deps ++ [ buildPackages.nukeReferences ];
}
  ''
    set -euo pipefail
    export bin_dir='${bin_dir}'
    export exe_dir='${exe_dir}'
    export lib_dir='${lib_dir}'
    export target_prefix='${stdenv.cc.targetPrefix}'
    ${if builtins.pathExists "${path}/bin" then ''
      find '${path}/bin' -type f -executable -print0 | xargs -0 --max-args 1 ${cfg.script} "$out"
    '' else ''
      ${cfg.script} "$out" ${lib.escapeShellArg path}
    ''}
    find $out -empty -type d -delete
  ''
