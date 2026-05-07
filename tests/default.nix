# tests/default.nix
#
# Entry point for the NixOS configuration test suite.
#
# Two flavors of tests live here:
#   1. VM tests  — boot a real NixOS VM with one of our modules and assert
#                  the resulting system behaves correctly. Slow but real.
#   2. Eval tests — pure-Nix derivations that force evaluation of host
#                   configs or assert specific config attribute values.
#                   Fast; catch typos, type errors, broken assertions.
#
# Run a single test:
#   nix build .#checks.x86_64-linux.<name>
#
# Run everything:
#   nix flake check
#
# When iterating on a VM test interactively, build
# `.#checks.x86_64-linux.<name>.driverInteractive` for a Python REPL inside
# the VM.

{ pkgs, self, inputs }:

let
  lib = pkgs.lib;
  callTest = path: import path { inherit pkgs self inputs lib; };
in
{
  # --- VM tests (modules in isolation) ------------------------------------
  core-module    = callTest ./vm/core-module.nix;
  ssh-tailscale  = callTest ./vm/ssh-tailscale.nix;

  # --- Eval tests (no VM, fast) -------------------------------------------
  eval-hosts        = callTest ./eval/hosts.nix;
  eval-assertions   = callTest ./eval/assertions.nix;
  eval-boot-loaders = callTest ./eval/boot-loaders.nix;
}
