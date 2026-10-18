# modules/home-manager/hyprland/theme/default.nix
# The single source of truth for how the Hyprland session looks. A palette
# (./palettes/*.nix) supplies colors; this module derives everything the other
# modules need from it, so no component hard-codes a hex value.
#
# Switching themes: add ./palettes/<name>.nix with the same role names, list it
# in `palettes` below, and set `theme.name`. Colors, wallpapers and every
# generated stylesheet follow.
#
# This only themes the Hyprland session. kitty/fish keep their own Catppuccin
# ports (catppuccin/nix, see core.nix), which both sessions share.

{ config, lib, ... }:

let
  inherit (lib) mkOption types;

  cfg = config.theme;

  palettes = {
    catppuccin-macchiato = import ./palettes/catppuccin-macchiato.nix;
  };

  palette = palettes.${cfg.name};
  colors = palette.colors // {
    accent = palette.colors.${cfg.accent};
  };

  # 0.0-1.0 → two hex digits
  byte =
    alpha:
    let
      h = lib.toHexString (builtins.floor (alpha * 255 + 0.5));
    in
    if lib.stringLength h == 1 then "0${h}" else h;

  channel = hex: i: toString (lib.fromHexString (builtins.substring (i * 2) 2 hex));

  fn = {
    # "#rrggbb"
    hex = role: "#${colors.${role}}";
    # "#rrggbbaa" (rofi)
    hexA = role: alpha: "#${colors.${role}}${byte alpha}";
    # "rgb(rrggbb)" / "rgba(rrggbbaa)" (Hyprland, hyprlock)
    hypr = role: "rgb(${colors.${role}})";
    hyprA = role: alpha: "rgba(${colors.${role}}${byte alpha})";
    # "rgba(r, g, b, a)" (CSS)
    css =
      role: alpha:
      let
        h = colors.${role};
      in
      "rgba(${channel h 0}, ${channel h 1}, ${channel h 2}, ${toString alpha})";

    # GTK CSS named colors (@bg, @fg, @accent, ...), for Waybar/swaync/swayosd.
    cssDefines = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: value: "@define-color ${name} #${value};") colors
    );

    # rasi variables, for rofi.
    rasiVars = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: value: "  ${name}: #${value};") colors
    );
  };
in
{
  options.theme = {
    name = mkOption {
      type = types.enum (lib.attrNames palettes);
      default = "catppuccin-macchiato";
      description = "Which palette the Hyprland session uses.";
    };

    accent = mkOption {
      type = types.enum [
        "red"
        "orange"
        "yellow"
        "green"
        "teal"
        "sky"
        "blue"
        "lavender"
        "purple"
        "pink"
      ];
      default = "blue";
      description = "Hue used for focus, selection and highlights.";
    };

    scheme = mkOption {
      type = types.enum [
        "dark"
        "light"
      ];
      readOnly = true;
      default = palette.scheme;
      description = "Whether the active palette is a dark or light scheme.";
    };

    colors = mkOption {
      type = types.attrsOf types.str;
      readOnly = true;
      default = colors;
      description = "Role → bare hex. Includes `accent`.";
    };

    wallpapers = mkOption {
      type = types.path;
      readOnly = true;
      default = palette.wallpapers;
      description = "Directory of wallpapers belonging to the active palette.";
    };

    fonts = {
      ui = mkOption {
        type = types.str;
        default = "Inter";
        description = "Proportional UI font (bar, launcher, notifications, lock screen).";
      };
      mono = mkOption {
        type = types.str;
        default = "FiraCode Nerd Font";
        description = "Monospace font.";
      };
      icons = mkOption {
        type = types.str;
        default = "Symbols Nerd Font";
        description = "Icon glyph font (Nerd Font symbols).";
      };
    };

    lib = mkOption {
      type = types.attrsOf types.raw;
      readOnly = true;
      default = fn;
      description = "Color-format helpers derived from the palette.";
    };
  };
}
