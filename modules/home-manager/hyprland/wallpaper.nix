# modules/home-manager/hyprland/wallpaper.nix
# Wallpaper via hyprpaper (fully declarative — the config is a static file; no
# imperative `swww img` calls). Phase 1 ships a wallpaper generated at build
# time from Catppuccin Macchiato colors, so no binary asset needs committing.
# Phase 2 points this at config.theme.wallpaper (a committed image).

{ pkgs, ... }:

let
  # Diagonal gradient between macchiato `base` and `crust`. Pure and
  # reproducible: the PNG is built in the Nix store from imagemagick.
  wallpaper =
    pkgs.runCommand "macchiato-gradient.png"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        magick -size 3840x2160 -define gradient:angle=135 \
          gradient:'#24273a'-'#181926' "$out"
      '';
in
{
  services.hyprpaper = {
    enable = true;
    settings = {
      splash = false;
      ipc = "off";
      preload = [ "${wallpaper}" ];
      # ",<path>" applies to every monitor.
      wallpaper = [ ",${wallpaper}" ];
    };
  };
}
