# modules/home-manager/hyprland/rofi.nix
# Launcher and the shared popup style. One theme, three shapes:
#   launcher  app launcher (Super+Space)
#   menu      narrow list, no icons: power menu, clipboard, keybinds cheat sheet
#   grid      thumbnail grid: wallpaper picker
# The scripts call them by name (`rofi -theme menu`); rofi finds the files in
# ~/.local/share/rofi/themes. pkgs.rofi is Wayland-native since rofi 2.0.

{ config, ... }:

let
  t = config.theme.lib;
  fonts = config.theme.fonts;
in
{
  programs.rofi = {
    enable = true;
    terminal = "kitty";
    theme = "launcher";
    extraConfig = {
      modi = "drun,run,window";
      show-icons = true;
      icon-theme = "Papirus-Dark";
      drun-display-format = "{name}";
      display-drun = "";
      display-run = "";
      display-window = "";
      window-format = "{c}  ·  {t}";
      matching = "fuzzy";
      sort = true;
    };
  };

  xdg.dataFile = {
    "rofi/themes/launcher.rasi".text = ''
      * {
      ${t.rasiVars}
        font: "${fonts.ui} 12";
        background-color: transparent;
        text-color: @fg;
      }

      window {
        location: center;
        anchor: center;
        width: 560px;
        background-color: ${t.hexA "bg" 0.9};
        border: 2px;
        border-color: @surfaceAlt;
        border-radius: 16px;
      }

      mainbox {
        padding: 12px;
        spacing: 10px;
        children: [ inputbar, listview ];
      }

      inputbar {
        padding: 12px 14px;
        spacing: 10px;
        background-color: @surface;
        border-radius: 12px;
        children: [ prompt, entry ];
      }
      prompt {
        text-color: @accent;
      }
      entry {
        placeholder: "Search";
        placeholder-color: @fgDim;
      }

      listview {
        lines: 8;
        columns: 1;
        scrollbar: false;
        fixed-height: true;
        spacing: 4px;
        cycle: false;
      }

      element {
        padding: 8px 12px;
        spacing: 12px;
        border-radius: 10px;
      }
      element selected.normal,
      element selected.active,
      element selected.urgent {
        background-color: @surface;
        text-color: @accent;
      }
      element-icon {
        size: 28px;
        vertical-align: 0.5;
      }
      element-text {
        vertical-align: 0.5;
        text-color: inherit;
        highlight: bold ${t.hex "accent"};
      }

      message {
        padding: 10px 14px;
        background-color: @surface;
        border-radius: 12px;
      }
    '';

    "rofi/themes/menu.rasi".text = ''
      @import "launcher"

      window {
        width: 360px;
      }
      inputbar {
        enabled: false;
      }
      element-icon {
        enabled: false;
      }
      listview {
        lines: 6;
        fixed-height: false;
      }
    '';

    "rofi/themes/grid.rasi".text = ''
      @import "launcher"

      window {
        width: 960px;
      }
      inputbar {
        enabled: false;
      }
      listview {
        columns: 3;
        lines: 3;
        fixed-height: false;
        spacing: 10px;
      }
      element {
        orientation: vertical;
        padding: 6px;
        spacing: 2px;
      }
      element-icon {
        size: 11em;
        horizontal-align: 0.5;
      }
      element-text {
        horizontal-align: 0.5;
      }
    '';
  };
}
