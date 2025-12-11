# modules/home-manager/common.nix
# Shared user configuration across all systems

{ inputs, ... }:

{
  imports = [
    inputs.catppuccin.homeModules.catppuccin
  ];

  # Catppuccin theme - base configuration
  catppuccin = {
    enable = true;
    flavor = "macchiato";
    accent = "mauve";
  };

  home = {
    username = "leyton";
    homeDirectory = "/home/leyton";
    stateVersion = "24.11";
  };

  # Fish shell - basic setup
  programs.fish = {
    enable = true;
    shellInit = ''
      starship init fish | source
      set fish_greeting ""
      fastfetch
    '';
    shellAliases = {
      ls = "eza -F";
      ll = "eza -lah";
      g = "git";
    };
  };

  # Direnv for automatic Nix shell activation
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    settings = {
      container.disabled = true;
      python.disabled = true;
    };
  };

  # Git
  programs.git = {
    enable = true;
    settings = {
      user = {
        email = "leyton.houck@gmail.com";
        name = "boxsitter";
      };
      core = {
        autocrlf = "input";  # Convert CRLF to LF on commit, keep LF on checkout
        eol = "lf";          # Always use LF in the working directory
      };
    };
  };

  # Kitty terminal
  programs.kitty = {
    enable = true;
    themeFile = "Catppuccin-Macchiato";
    settings = {
      font_family = "FiraCode Nerd Font";
      font_size = 11;
      background_opacity = "0.95";
      confirm_os_window_close = 0;
      linux_display_server = "wayland";
      wayland_titlebar_color = "background";
    };
  };

  # Disable kitty's systemd integration via environment variable
  home.sessionVariables = {
    KITTY_ENABLE_WAYLAND = "1";
    XCURSOR_SIZE = "14";
  };

  # Fastfetch configuration
  xdg.configFile."fastfetch/config.jsonc".source = ./dotfiles/fastfetch-config.jsonc;
}
