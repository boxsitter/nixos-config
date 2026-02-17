# modules/home-manager/gnome.nix
# GNOME preferences managed via Home Manager (dconf).

{ pkgs, ... }:

{
  dconf = {
    enable = true;

    settings = {
      "org/gnome/desktop/wm/preferences" = {
        # Buttons on the right in the order requested.
        # Left side is empty (before the ':').
        button-layout = ":minimize,maximize,close";
      };

      # Enable user extensions
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = [
          "appindicatorsupport@rgcjonas.gmail.com"
          "gSnap@micahosborne"
        ];
      };

      # Legacy applications theme support
      "org/gnome/desktop/interface" = {
        font-antialiasing = "rgba";
        font-hinting = "slight";
      };

      # Prevent screen from turning off on AC power
      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "nothing";
        sleep-inactive-ac-timeout = 0;
      };
    };
  };

  # Install GNOME extensions
  home.packages = [
    pkgs.gnomeExtensions.gsnap
  ];
}
