{ pkgs }:
path: # May be:
      #  1) a derivation,
      #  2) a path to a directory containing bin/, or
      #  3) a path to an executable.
let
  print-needed-elf = pkgs.writeScriptBin
    "print-needed-elf"
    '''${pkgs.python3}'/bin/python ${./print_needed_elf.py} "$@"'';

  cfg =
    if pkgs.stdenv.isDarwin then
      {
        deps = with pkgs; [darwin.binutils darwin.sigtool];
        script = "bash ${./bundle-macos.sh}";
      }
    else if pkgs.stdenv.isLinux then
      {
        deps = [pkgs.glibc print-needed-elf];
        script = "bash ${./bundle-linux.sh}";
      }
    else
      throw "Unsupported platform: only darwin and linux are supported";

  name = if pkgs.lib.isDerivation path then path.name else builtins.baseNameOf path;
in
pkgs.runCommand "bundle-${name}" {
  nativeBuildInputs = cfg.deps ++ [pkgs.nukeReferences];
} ''
  set -euo pipefail
  ${if builtins.pathExists "${path}/bin" then ''
    find '${path}/bin' -type f -executable -print0 | xargs -0 --max-args 1 ${cfg.script} "$out"
  '' else ''
    ${cfg.script} "$out" ${pkgs.lib.escapeShellArg path}
  ''}
  find "$out" -type f -exec nuke-refs '{}' \;
''
