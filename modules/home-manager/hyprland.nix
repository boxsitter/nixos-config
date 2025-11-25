# modules/home-manager/hyprland.nix
# Hyprland window manager user configuration

{ config, pkgs, inputs, ... }:

{
  # Catppuccin theme for Hyprland components
  catppuccin = {
    waybar.enable = true;
    hyprland.enable = true;
  };

  # Hyprland window manager configuration
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";
      
      # Monitor configuration for Samsung Odyssey G9 Neo
      # Currently limited to 120Hz - 240Hz causes black screen (DSC issue)
      # HDR Note: Your monitor supports HDR but Hyprland 0.52.1 has limited HDR support
      monitor = [
        "DP-4,7680x2160@120,0x0,1"
        # Fallback monitors for unrecognized outputs
        ",preferred,auto,1"
      ];
      
      # Cursor configuration
      cursor = {
        # Enable hardware cursor for better performance
        no_hardware_cursors = false;
      };
      
      # Debug settings
      debug = {
        disable_logs = false;
      };
      
      # Startup applications - commented out for debugging
      # exec-once = [
      #   "waybar"
      #   "hyprpaper"
      # ];
      
      # Keybindings
      bind = [
        "$mod, RETURN, exec, kitty"
        "$mod, Q, killactive"
        "$mod, C, exec, wofi --show drun"
        "$mod, F, fullscreen"
        "$mod, V, togglefloating"
        
        # Move focus
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        
        # Workspace switching
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        
        # Move to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
      ];
      
      # Input configuration
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = false;
        };
      };
      
      # General settings
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(b4befeee) rgba(cba6f7ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
      };
      
      # Decoration
      decoration = {
        rounding = 8;
        blur = {
          enabled = false;  # Disable for better performance on NVIDIA
        };
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
      };
      
      # Animations
      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };
      
      # Misc settings
      misc = {
        vfr = true;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };
    };
  };

  # Waybar status bar
  programs.waybar = {
    enable = true;
  };

  # Hyprland-specific packages
  home.packages = with pkgs; [
    # Wayland utilities
    wl-clipboard
    grim
    slurp
    hyprpaper
    hyprlock
    wofi  # App launcher
    
    # Applications
    firefox
    vlc
    
    # Qt theming
    libsForQt5.qtstyleplugin-kvantum
    qt6Packages.qtstyleplugin-kvantum
  ];

  # GTK theme (for file pickers, etc.)
  gtk.enable = true;

  # Qt theme
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };
}
