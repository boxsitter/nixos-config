# modules/home-manager/hyprland/theme/palettes/catppuccin-macchiato.nix
# Catppuccin Macchiato (https://catppuccin.com/palette, MIT).
#
# A palette is plain data. Every palette must define the same role names (the
# theme module turns them into CSS, rasi, Hyprland and hyprlock colors), so a
# new theme is one new file next to this one plus an entry in ../default.nix.
# Values are bare hex (no leading #).

{
  scheme = "dark";

  colors = {
    # Surfaces, darkest to lightest.
    bgDeep = "181926"; # crust
    bgAlt = "1e2030"; # mantle
    bg = "24273a"; # base
    surface = "363a4f"; # surface0
    surfaceAlt = "494d64"; # surface1
    surfaceHi = "5b6078"; # surface2

    # Text, faintest to strongest.
    fgDim = "6e738d"; # overlay0
    fgMuted = "a5adcb"; # subtext0
    fg = "cad3f5"; # text

    # Hues.
    red = "ed8796";
    orange = "f5a97f"; # peach
    yellow = "eed49f";
    green = "a6da95";
    teal = "8bd5ca";
    sky = "91d7e3";
    blue = "8aadf4";
    lavender = "b7bdf8";
    purple = "c6a0f6"; # mauve
    pink = "f5bde6";
  };

  # Wallpapers that belong to this palette (the picker only offers these).
  wallpapers = ../../../../../resources/wallpapers/catppuccin-macchiato;
}
