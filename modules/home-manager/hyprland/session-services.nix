# modules/home-manager/hyprland/session-services.nix
# Tray applets, agents, and helpers that must run in the Hyprland session but
# NOT in GNOME. Most home-manager wayland services follow wayland.systemd.target
# (set to hyprland-session.target in hyprland.nix) and scope themselves
# automatically. network-manager-applet is the exception — it hardcodes
# graphical-session.target and Requires=tray.target, so left alone it would
# start inside GNOME and drag Waybar in via tray.target. It is rescoped by hand.

{ lib, ... }:

{
  # --- Auto-scoped via wayland.systemd.target = hyprland-session.target ---

  services.hyprpolkitagent.enable = true; # GNOME keeps gnome-shell's own agent
  services.playerctld.enable = true; # MPRIS proxy for media keys / Waybar
  services.cliphist = {
    enable = true; # runs the wl-paste clipboard watchers itself
    allowImages = true;
  };

  services.udiskie = {
    enable = true;
    tray = "auto"; # GNOME has gvfs automount; Hyprland relies on this
  };

  # --- Scoped via the module's own systemdTargets option ---

  services.blueman-applet.enable = true;
  services.blueman-applet.systemdTargets = [ "hyprland-session.target" ];

  # --- The manual rescope (see header) ---

  services.network-manager-applet.enable = true;
  systemd.user.services.network-manager-applet = {
    Unit.After = lib.mkForce [
      "hyprland-session.target"
      "tray.target"
    ];
    Unit.PartOf = lib.mkForce [ "hyprland-session.target" ];
    Install.WantedBy = lib.mkForce [ "hyprland-session.target" ];
  };
}
