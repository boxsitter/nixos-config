# tests/eval/hyprland-config.nix
#
# Asks Hyprland itself whether each host's generated Lua config is valid
# (`Hyprland --verify-config`). Needs no VM, no display and takes seconds, so it
# catches a typo in a bind, a window rule or a host override long before a
# login does. Complements tests/vm/hyprland-session.nix, which proves the
# session actually works.

{ pkgs, self, lib }:

let
  hosts = [ "desktop" "laptop" ];

  verify =
    host:
    let
      cfg = self.nixosConfigurations.${host}.config;
      files = cfg.home-manager.users.leyton.home-files;
      hyprland = cfg.programs.hyprland.package;
    in
    ''
      echo "== ${host}"
      d=$(mktemp -d)
      cp -rL ${files}/.config/hypr "$d/hypr"
      chmod -R u+w "$d"
      export HOME="$d" XDG_CONFIG_HOME="$d" XDG_RUNTIME_DIR="$d"
      ${hyprland}/bin/Hyprland --verify-config -c "$d/hypr/hyprland.lua" 2>&1 | tee "$d/out"
      grep -q "config ok" "$d/out" || { echo "${host}: Hyprland rejected the generated config" >&2; exit 1; }
    '';
in
pkgs.runCommand "hyprland-config"
  { meta.description = "Hyprland accepts every host's generated config"; }
  ''
    ${lib.concatMapStringsSep "\n" verify hosts}
    echo "config ok for: ${lib.concatStringsSep ", " hosts}" > $out
  ''
