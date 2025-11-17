# home/leyton/vm.nix
# VirtualBox VM user configuration - similar to desktop but no NVIDIA-specific settings

{ config, pkgs, inputs, ... }:

{
  imports = [
    ./default.nix  # Import shared config
    inputs.catppuccin.homeManagerModules.catppuccin
  ];

  # Catppuccin theme
  catppuccin = {
    enable = true;
    flavor = "macchiato";
    accent = "mauve";
  };

  # Kitty terminal with Catppuccin theme
  programs.kitty = {
    enable = true;
    catppuccin.enable = true;
    font = {
      name = "0xProto Nerd Font";
      size = 14;
    };
    settings = {
      background_opacity = "0.9";
      cursor_shape = "beam";
    };
  };

  # Hyprland window manager configuration (same as desktop)
  wayland.windowManager.hyprland = {
    enable = true;
    catppuccin.enable = true;
    settings = {
      "$mod" = "SUPER";
      
      exec-once = [
        "waybar"
        "hyprpaper"
      ];
      
      bind = [
        "$mod, RETURN, exec, kitty"
        "$mod, Q, killactive"
        "$mod, C, exec, wofi --show drun"
        "$mod, F, fullscreen"
        "$mod, V, togglefloating"
        
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
      ];
      
      input = {
        kb_layout = "us";
        follow_mouse = 1;
      };
      
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(b4befeee) rgba(cba6f7ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
      };
      
      decoration = {
        rounding = 8;
        blur = {
          enabled = true;  # Can enable blur in VM (no NVIDIA issues)
          size = 3;
          passes = 1;
        };
      };
      
      animations = {
        enabled = true;
      };
      
      misc = {
        vfr = true;
        disable_hyprland_logo = true;
      };
    };
  };

  # Waybar
  programs.waybar = {
    enable = true;
    catppuccin.enable = true;
  };

  # VM-specific packages
  home.packages = with pkgs; [
    wl-clipboard
    grim
    slurp
    hyprpaper
    hyprlock
    firefox
    vlc
    
    # Qt theming
    libsForQt5.qtstyleplugin-kvantum
    qt6Packages.qtstyleplugin-kvantum
  ];

  # GTK theme
  gtk.enable = true;

  # Qt theme
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };
}
