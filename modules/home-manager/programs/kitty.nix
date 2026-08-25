# modules/home-manager/programs/kitty.nix
# Kitty terminal configuration

{ lib, ... }:

{
  catppuccin.kitty.enable = true;

  programs.kitty = {
    enable = true;
    font = {
      name = "FiraCode Nerd Font";
      size = lib.mkDefault 13;  # baseline; hosts may override (e.g. laptop = 11)
    };
    settings = {
      # Behavior
      enable_audio_bell = false;
      cursor_trail = 1;
      cursor_blink_interval = 0;
      shell_integration = "no-cursor";

      # Window
      # GNOME blur is provided by the compositor/extension; Kitty needs some
      # transparency for the blur to be visible.
      window_padding_width = "0 10";
      confirm_os_window_close = 0;

      # Tabs (minimal powerline styling)
      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_title_template = "{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}";

      # Wayland
      linux_display_server = "wayland";
      wayland_titlebar_color = "background";
    };
  };
}
