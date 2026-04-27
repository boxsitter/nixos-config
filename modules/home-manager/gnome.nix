# modules/home-manager/gnome.nix
# GNOME preferences managed via Home Manager (dconf).

{ pkgs, lib, ... }:

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

      # Prevent screen from blanking or sleeping.
      # NOTE: serverFlagsSection in gnome.nix configures the X server and has no
      # effect on Wayland sessions. These dconf keys are the correct Wayland controls.
      #
      # idle-delay: 0 = never blank. Set to e.g. 300 if you want a 5-min blank.
      "org/gnome/desktop/session" = {
        idle-delay = lib.hm.gvariant.mkUint32 300; # seconds before screen blanks (0 = never)
      };

      "org/gnome/settings-daemon/plugins/power" = {
        # Prevent screen from dimming before blanking
        idle-dim = false;
        # Prevent suspend on AC and battery (laptop-relevant: both must be set)
        sleep-inactive-ac-type = "nothing";
        sleep-inactive-ac-timeout = 0;
        sleep-inactive-battery-type = "nothing";
        sleep-inactive-battery-timeout = 0;
      };

      # Disable accessibility keyboard features that can be accidentally
      # triggered during a bad shutdown (e.g. Shift+NumLock activates
      # Mouse Keys, causing keyboard input to move the cursor).
      "org/gnome/desktop/a11y/keyboard" = {
        mousekeys-enable    = false; # numpad/arrow keys must not move the cursor
        stickykeys-enable   = false; # modifier keys must not latch
        bouncekeys-enable   = false; # repeated key filter off
        slowkeys-enable     = false; # delayed key acceptance off
        enable              = false; # master accessibility keyboard toggle off
      };
    };
  };

  # Install GNOME extensions
  home.packages = [
    pkgs.gnomeExtensions.gsnap
  ];
}
