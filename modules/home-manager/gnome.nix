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

      # Enable user extensions and ensure Blur My Shell is enabled.
      "org/gnome/shell" = {
        disable-user-extensions = false;
        # Include AppIndicator so tray icons keep working.
        enabled-extensions = [
          "appindicatorsupport@rgcjonas.gmail.com"
          "blur-my-shell@aunetx"
          "gSnap@micahosborne"
        ];
      };

      # Legacy applications theme support
      "org/gnome/desktop/interface" = {
        font-antialiasing = "rgba";
        font-hinting = "slight";
      };
    };
  };

  # Install the extension so GNOME can load it.
  home.packages = [
    pkgs.gnomeExtensions.blur-my-shell
    pkgs.gnomeExtensions.gsnap
  ];
}
