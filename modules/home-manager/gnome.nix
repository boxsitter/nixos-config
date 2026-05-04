# modules/home-manager/gnome.nix
# GNOME preferences and desktop theming managed via Home Manager.

{ pkgs, ... }:

{
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

    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  # Prevent catppuccin from injecting CSS into GTK4 (avoids mismatched headerbars)
  xdg.configFile."gtk-4.0/gtk.css".text = "";

  dconf = {
    enable = true;

    settings = {
      "org/gnome/desktop/wm/preferences" = {
        # Buttons on the right; left side empty (before the ':').
        button-layout = ":minimize,maximize,close";
      };

      # Enable user extensions
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = [
          "appindicatorsupport@rgcjonas.gmail.com"
          # gSnap removed: crashes GNOME Shell on login with:
          # JS ERROR: TypeError: can't access property Symbol.iterator,
          # this.connected.changed is undefined (extension.js:1580)
          # The extension is abandoned and incompatible with current GNOME.
        ];
      };

      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "adw-gtk3";
        icon-theme = "Papirus-Dark";
        font-antialiasing = "rgba";
        font-hinting = "slight";
      };

      # Background (Catppuccin Macchiato base/mantle)
      "org/gnome/desktop/background" = {
        primary-color = "#24273a";
        secondary-color = "#1e2030";
      };
    };
  };
}
