# modules/home-manager/hyprland.nix
# Hyprland window manager user configuration

{ pkgs, ... }:

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
        "DP-4,7680x2160@120,0x0,1.25"
        # Fallback monitors for unrecognized outputs
        ",preferred,auto,1"
      ];
      
      # Cursor configuration
      cursor = {
        no_hardware_cursors = false;
        default_monitor = "DP-4";
      };

      # Environment variables for cursor
      env = [
        "XCURSOR_SIZE,14"
        "XCURSOR_THEME,catppuccin-macchiato-dark-cursors"
      ];
      
      # Debug settings
      debug = {
        disable_logs = false;
      };
      
      # Startup applications
      exec-once = [
        "waybar"
        "dunst"
      ];
      
      # Keybindings
      bind = [
        "$mod, RETURN, exec, kitty"
        "$mod, Q, killactive"
        "$mod, M, exit"
        "$mod, C, exec, wofi --show drun"
        "$mod, F, fullscreen"
        "$mod, V, togglefloating"
        "$mod, P, pseudo"
        "$mod, J, togglesplit"
        
        # Move focus with arrow keys
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        
        # Move focus with vim keys
        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"
        
        # Move windows
        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, down, movewindow, d"
        
        # Resize windows
        "$mod CTRL, left, resizeactive, -20 0"
        "$mod CTRL, right, resizeactive, 20 0"
        "$mod CTRL, up, resizeactive, 0 -20"
        "$mod CTRL, down, resizeactive, 0 20"
        
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
        
        # Screenshot
        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
        "$mod, Print, exec, grim - | wl-copy"
      ];
      
      # Mouse bindings
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
      
      # Input configuration
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        accel_profile = "adaptive";
        force_no_accel = false;
        sensitivity = -0.5;  # Lower base sensitivity (-1.0 to 1.0)
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
        allow_tearing = false;
        resize_on_border = true;
        extend_border_grab_area = 15;
      };

      # Disable client-side decorations (no minimize/maximize buttons)
      windowrulev2 = [
        "suppressevent maximize, class:.*"
        "noblur, class:.*"
      ];

      # Dwindle layout settings
      dwindle = {
        pseudotile = true;
        preserve_split = true;
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
    };
  };

  # Waybar status bar
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [ "cpu" "memory" "tray" ];

        "hyprland/workspaces" = {
          format = "{id}";
        };

        clock = {
          format = "{:%H:%M}";
        };

        cpu = {
          format = "CPU {usage}%";
        };

        memory = {
          format = "RAM {}%";
        };

        tray = {
          spacing = 10;
        };
      };
    };
  };

  # Dunst notification daemon
  services.dunst = {
    enable = true;
  };

  # GTK theme (for file pickers, etc.)
  gtk.enable = true;

  # Cursor theme
  home.pointerCursor = {
    gtk.enable = true;
    name = "catppuccin-macchiato-dark-cursors";
    package = pkgs.catppuccin-cursors.macchiatoDark;
    size = 14;
  };

  # Qt theme
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };
}
