# modules/home-manager/hyprland/session-services.nix
# Agents, applets and helpers that must run in the Hyprland session and NOT in
# GNOME (which brings its own: gnome-shell's polkit agent, notification daemon,
# network/bluetooth menus, gvfs automounting, ...).
#
# Several Home Manager service modules do not honour wayland.systemd.target:
# udiskie is hard-wired to graphical-session.target, playerctld to
# default.target, nm-applet to graphical-session.target + tray.target. Left
# alone they would start inside GNOME (and tray.target would pull a bar in), so
# those three are defined here by hand. tests/eval/assertions.nix fails the
# build if anything in this tree ever becomes wanted outside the Hyprland target.

{ lib, pkgs, ... }:

let
  target = "hyprland-session.target";

  sessionService =
    {
      description,
      exec,
      after ? [ ],
    }:
    {
      Unit = {
        Description = description;
        PartOf = [ target ];
        After = [ target ] ++ after;
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        ExecStart = exec;
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ target ];
    };
in
{
  # notify-send, for scripts and for trying the notification styling.
  home.packages = [ pkgs.libnotify ];

  # --- Honour wayland.systemd.target (hyprland.nix) --------------------------
  services.hyprpolkitagent.enable = true; # GNOME keeps gnome-shell's own agent
  services.cliphist = {
    enable = true; # runs the wl-paste watchers itself; picker is clipboard-menu
    allowImages = true;
  };
  services.hyprsunset.enable = true; # the daemon behind `nightlight`

  # --- Scoped through the module's own option --------------------------------
  # Bluetooth pairing agent + tray menu.
  services.blueman-applet = {
    enable = true;
    systemdTargets = [ target ];
  };

  # --- Hand-written (see header) ---------------------------------------------
  systemd.user.services = {
    # Secret agent for NetworkManager. This matters: Wi-Fi passwords that GNOME
    # saved as "this user only" live in the keyring and are only handed to a
    # secret agent, so without nm-applet those networks would not auto-connect.
    nm-applet = sessionService {
      description = "NetworkManager applet and secret agent";
      exec = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
      after = [ "waybar.service" ];
    };

    # Automount removable media (GNOME gets this from gvfs/gnome-shell).
    udiskie = sessionService {
      description = "Removable media automounter";
      exec = "${lib.getExe pkgs.udiskie} --automount --notify --no-tray";
    };

    # MPRIS proxy so media keys act on the most recently active player.
    playerctld = sessionService {
      description = "MPRIS proxy (most recent player)";
      exec = "${pkgs.playerctl}/bin/playerctld";
    };
  };
}
