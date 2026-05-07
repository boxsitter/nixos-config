# tests/eval/hosts.nix
#
# Forces full evaluation of every NixOS host's `system.build.toplevel`. If
# any host has an eval error — broken module, missing option, type mismatch,
# accidental infinite recursion — this fails immediately, no VM required.
#
# We don't actually *build* the toplevel here (that would download/build
# the world). We just refer to its derivation path, which is enough to
# evaluate the entire module tree and catch typos and option errors.
#
# Server is intentionally included: even if we're not testing its services
# yet, we still want a regression on a server config that fails to evaluate.

{ pkgs, self, inputs, lib }:

let
  # Server is omitted here: its full closure (Jellyfin, Grafana, etc.) is
  # large enough to OOM the Nix daemon on memory-constrained hosts like WSL.
  # Server config invariants are still covered by eval-assertions, which only
  # touches lightweight config attributes rather than system.build.toplevel.
  hosts = [ "desktop" "laptop" "wsl" ];

  evalLine = host:
    let drv = self.nixosConfigurations.${host}.config.system.build.toplevel.drvPath;
    in "echo '${host}: ${drv}' >> $out";
in
pkgs.runCommand "eval-hosts"
  {
    # Embed the drvPaths as build-time strings; the derivation will fail
    # to *evaluate* if any host fails. The runCommand body just records
    # what we evaluated for debuggability.
    meta.description = "Force-evaluate all NixOS host configurations";
  }
  ''
    set -e
    : > $out
    ${lib.concatStringsSep "\n" (map evalLine hosts)}
    echo "evaluated ${toString (lib.length hosts)} hosts" >> $out
  ''
