# modules/home-manager/theming.nix
# Global Catppuccin Macchiato theming for GNOME and applications

{ pkgs, catppuccin, ... }:

{
  imports = [
    catppuccin.homeModules.catppuccin
  ];

  # Enable Catppuccin Macchiato globally
  catppuccin = {
    enable = true;
    flavor = "macchiato";
    accent = "blue";

    # Enable theming for specific applications
    kitty.enable = true;
    fish.enable = true;
    starship.enable = false;  # Disabled - using custom config
    rofi.enable = true;
  };

  # GTK theming
  gtk = {
    enable = true;
    
    theme = {
      name = "adw-gtk3";
      package = pkgs.adw-gtk3;
    };

    cursorTheme = {
      name = "Bibata-Modern-Ice";
      size = 24;
      package = pkgs.bibata-cursors;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # Ensure GTK4 does not import Catppuccin CSS (avoid mismatched headerbars)
  xdg.configFile."gtk-4.0/gtk.css".text = "";

  # Qt theming with kvantum (required for catppuccin Qt theming)
  # Disable Qt theming here; let apps use their defaults to avoid conflicts
  qt.enable = false;

  # GNOME-specific settings via dconf
  dconf.settings = {
    # Interface settings
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3";
      icon-theme = "Papirus-Dark";
    };

    # Background color (Catppuccin Macchiato base color)
    "org/gnome/desktop/background" = {
      primary-color = "#24273a";
      secondary-color = "#1e2030";
    };
  };

  # Install additional packages for theming support
  home.packages = with pkgs; [
    # GNOME Tweaks for manual theme adjustments if needed
    gnome-tweaks
    
    # For checking/testing themes
    dconf-editor
  ];

  # Ensure GNOME Shell can access themes
  home.sessionVariables = {
    GTK_THEME = "adw-gtk3";
  };
}
