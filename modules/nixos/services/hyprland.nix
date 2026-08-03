# ./modules/nixos/services/hyprland.nix
# Hyprland session alongside GNOME. GDM stays the display manager; this module
# only adds a second Wayland session entry. All shared desktop infrastructure
# (pipewire, bluetooth, gnome-keyring, fonts, GDM) is owned by
# services/gnome.nix and asserted below rather than duplicated here.
#
# See ../../hyprland.md for the full design and rationale.

{ config, lib, ... }:

{
  programs.hyprland = {
    enable = true;

    # UWSM is intentionally disabled. It pulls in programs.uwsm, which switches
    # services.dbus.implementation to dbus-broker system-wide — a behavioural
    # change to the GNOME session, which must stay identical. Session scoping is
    # instead handled in home-manager via hyprland-session.target.
    withUWSM = false;

    # xwayland.enable defaults to true.
  };

  # Per-desktop portal selection for the Hyprland session only. GNOME keeps
  # resolving through gnome-portals.conf (shipped by gnome-session via
  # xdg.portal.configPackages) and the existing common.default = "*" fallback in
  # gnome.nix — both untouched, so GNOME portal behaviour is byte-identical.
  # The [hyprland] section is only consulted when XDG_CURRENT_DESKTOP=Hyprland.
  xdg.portal.config.hyprland.default = [
    "hyprland"
    "gtk"
  ];

  # Registers the PAM service (security.pam.services.hyprlock) that hyprlock
  # needs to authenticate unlocks. Must be enabled system-side, not just in
  # home-manager.
  programs.hyprlock.enable = true;

  # nixpkgs' programs.hyprlock module implicitly does `services.hypridle.enable
  # = true`, and the system hypridle module hard-wires its user unit to
  # graphical-session.target. That collides with our home-manager hypridle unit
  # (scoped to hyprland-session.target via wayland.systemd.target): the merged
  # unit ends up wanted by BOTH targets, so hypridle also starts — and
  # crash-loops, since there's no wlroots compositor — inside the GNOME session.
  # Re-scope the system unit to the Hyprland session. We keep the system module
  # (not mkForce-disable it) because it also supplies hypridle's runtime PATH
  # (hyprland/hyprlock/procps); only the target is wrong.
  systemd.user.services.hypridle.wantedBy = lib.mkForce [ "hyprland-session.target" ];

  # D-Bus backend for blueman-applet. The applet itself only runs inside the
  # Hyprland session (scoped in home-manager); nothing blueman autostarts under
  # GNOME, so gnome-bluetooth is unaffected.
  services.blueman.enable = true;

  # This module deliberately does not configure audio, bluetooth, keyring or
  # fonts — it depends on services/gnome.nix providing them. Encode that as
  # assertions so a future refactor that drops the dependency fails loudly in
  # `nix flake check` (via tests/eval/hosts.nix) rather than silently at runtime.
  assertions = [
    {
      assertion =
        config.services.displayManager.gdm.enable && config.services.desktopManager.gnome.enable;
      message = "hyprland.nix expects services/gnome.nix (GDM + shared desktop infra) to be imported.";
    }
    {
      assertion = config.services.pipewire.enable && config.security.rtkit.enable;
      message = "hyprland.nix expects pipewire + rtkit from services/gnome.nix (audio + screenshare).";
    }
    {
      assertion =
        config.services.gnome.gnome-keyring.enable && config.security.pam.services.gdm.enableGnomeKeyring;
      message = "hyprland.nix expects gnome-keyring + GDM PAM unlock from services/gnome.nix.";
    }
  ];
}
