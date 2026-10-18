# ./modules/nixos/services/hyprland.nix
# Hyprland as a second session next to GNOME. GDM stays the display manager and
# this only adds a session entry, so GNOME is untouched. Shared desktop
# infrastructure (pipewire, bluetooth, keyring, dconf, GDM) comes from
# services/gnome.nix and is asserted below rather than duplicated here.
#
# Design and rationale: docs/hyprland.md

{
  config,
  pkgs,
  ...
}:

{
  programs.hyprland = {
    enable = true;

    # UWSM (a systemd session manager for Wayland compositors) is not used: it
    # would take over graphical-session.target ordering, which the home-manager
    # side already scopes with a plain hyprland-session.target that Hyprland
    # itself starts. One mechanism is simpler and equally robust. (The older
    # worry that UWSM flips the system D-Bus to dbus-broker no longer applies:
    # broker is already the NixOS default.)
    withUWSM = false;

    # nixpkgs' Hyprland ships two session entries. The "uwsm-managed" one starts
    # through UWSM, which this setup does not use, so choosing it at the GDM
    # login screen would just fail. Advertise only the plain session.
    #
    # Patches (patches/hyprland/): small behaviour changes with no config knob.
    # Hyprland is therefore built locally instead of substituted from the cache,
    # on the first rebuild and again whenever a flake update changes it or one of
    # its build inputs. A patch that stops applying fails the build, naming the
    # hunk: re-diff it against the new source, or drop it if upstream added a
    # setting for the same thing.
    #  - drag-tiled-keep-position: dragging a tiled window floats it with the
    #    cursor staying at the same relative spot, instead of snapping it, shrunk,
    #    to be centered on the cursor.
    #  - floating-default-size: a window floated for the first time gets a modest
    #    default size instead of keeping its (often screen-sized) tiled size.
    #  - workspace-popin-animation: a "popin" style for workspace animations
    #    (fade, and the whole workspace scales about the monitor center); used
    #    for the scratchpad.
    package = pkgs.hyprland.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        ../../../patches/hyprland/drag-tiled-keep-position.patch
        ../../../patches/hyprland/floating-default-size.patch
        ../../../patches/hyprland/workspace-popin-animation.patch
      ];
      passthru = old.passthru // {
        providedSessions = [ "hyprland" ];
      };
    });
  };

  # Portal choice for the Hyprland session only. GNOME keeps resolving through
  # gnome-portals.conf and the common.default = "*" fallback in gnome.nix; the
  # [hyprland] section is consulted only when XDG_CURRENT_DESKTOP=Hyprland.
  # Hyprland's portal does screenshots and screen sharing; the GTK portal
  # supplies file pickers and the color-scheme setting (dark mode) for GTK/Qt.
  xdg.portal.config.hyprland.default = [
    "hyprland"
    "gtk"
  ];

  # PAM service hyprlock authenticates against. Without it the lock screen can
  # never unlock. (programs.hyprlock.enable would add this but also drags in a
  # system-wide hypridle unit wired to graphical-session.target, i.e. GNOME;
  # the PAM service alone is all that is needed.)
  security.pam.services.hyprlock = { };

  # Backend for blueman (the Hyprland-only bluetooth tray/manager). Nothing here
  # runs under GNOME, which keeps using gnome-bluetooth.
  services.blueman.enable = true;

  # Automount backend for udiskie (GNOME gets the same from gvfs).
  services.udisks2.enable = true;

  # UI font and icon glyphs for the bar, launcher, notifications, lock screen.
  fonts.packages = with pkgs; [
    inter
    nerd-fonts.symbols-only
  ];

  # This module does not configure audio, bluetooth, keyring or dconf; it relies
  # on services/gnome.nix. Encode that so a refactor that drops the dependency
  # fails `nix flake check` instead of failing at runtime on first login.
  assertions = [
    {
      assertion =
        config.services.displayManager.gdm.enable && config.services.desktopManager.gnome.enable;
      message = "hyprland.nix expects services/gnome.nix (GDM + shared desktop infra) to be imported.";
    }
    {
      assertion = config.services.pipewire.enable && config.security.rtkit.enable;
      message = "hyprland.nix expects pipewire + rtkit from services/gnome.nix (audio, screen sharing).";
    }
    {
      assertion =
        config.services.gnome.gnome-keyring.enable && config.security.pam.services.gdm.enableGnomeKeyring;
      message = "hyprland.nix expects gnome-keyring + GDM PAM unlock from services/gnome.nix.";
    }
    {
      assertion = config.programs.dconf.enable;
      message = "hyprland.nix expects programs.dconf from services/gnome.nix (GTK settings, dark mode).";
    }
  ];
}
