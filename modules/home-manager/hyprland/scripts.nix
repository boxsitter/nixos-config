# modules/home-manager/hyprland/scripts.nix
# The small helper commands behind the keybinds and bar buttons (power-menu,
# screenshot, wallpaper, ...). Each is a real shell file in ./scripts, wrapped
# with writeShellApplication, which puts its dependencies on PATH and runs
# shellcheck at build time, so a typo fails `nixos-rebuild`, not a keypress.
#
# Other modules use `config.session.scripts.<name>` for absolute paths where the
# caller (a systemd unit like Waybar) cannot rely on PATH.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  mkScript =
    {
      name,
      deps,
      subs ? { },
    }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = deps;
      text = lib.replaceStrings (map (k: "@${k}@") (lib.attrNames subs)) (lib.attrValues subs) (
        builtins.readFile (./scripts + "/${name}.sh")
      );
    };

  wallpapers = builtins.path {
    path = config.theme.wallpapers;
    name = "wallpapers";
  };

  # Thumbnails for the picker, built once in the store from the committed images.
  thumbs =
    pkgs.runCommand "wallpaper-thumbs" { nativeBuildInputs = [ pkgs.imagemagick ]; }
      ''
        mkdir -p "$out"
        for f in ${wallpapers}/*; do
          case "$f" in *.jpg|*.jpeg|*.png|*.webp) ;; *) continue ;; esac
          n=$(basename "$f"); n="''${n%.*}"
          magick "$f" -auto-orient -thumbnail 640x360^ -gravity center -extent 640x360 \
            -quality 82 "$out/$n.jpg"
        done
      '';
in
{
  options.session.scripts = lib.mkOption {
    type = lib.types.attrsOf lib.types.package;
    readOnly = true;
    description = "Helper commands for the Hyprland session, by name.";
  };

  config = {
    session.scripts = {
      power-menu = mkScript {
        name = "power-menu";
        deps = with pkgs; [
          rofi
          hyprshutdown
          systemd
          coreutils
        ];
      };

      clipboard-menu = mkScript {
        name = "clipboard-menu";
        deps = with pkgs; [
          rofi
          cliphist
          wl-clipboard
        ];
      };

      keybinds = mkScript {
        name = "keybinds";
        deps = with pkgs; [
          rofi
          jq
          util-linux # column
        ];
        subs.mono = config.theme.fonts.mono;
      };

      screenshot = mkScript {
        name = "screenshot";
        deps = with pkgs; [
          hyprshot
          satty
          wl-clipboard
          coreutils
        ];
      };

      nightlight = mkScript {
        name = "nightlight";
        deps = with pkgs; [
          hyprsunset
          libnotify
          coreutils
        ];
      };

      wallpaper = mkScript {
        name = "wallpaper";
        deps = with pkgs; [
          awww
          rofi
          findutils
          coreutils
        ];
        subs = {
          wallpapers = "${wallpapers}";
          thumbs = "${thumbs}";
        };
      };
    };

    home.packages = lib.attrValues config.session.scripts;
  };
}
