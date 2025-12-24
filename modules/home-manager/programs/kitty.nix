# modules/home-manager/programs/kitty.nix
# Kitty terminal configuration

{ ... }:

{
  programs.kitty = {
    enable = true;
    settings = {
      font_family = "FiraCode Nerd Font";
      font_size = 11;
      background_opacity = "0.95";
      confirm_os_window_close = 0;
      linux_display_server = "wayland";
      wayland_titlebar_color = "background";
    };
  };

  # Kitty environment variables
  home.sessionVariables = {
    KITTY_ENABLE_WAYLAND = "1";
  };
}
