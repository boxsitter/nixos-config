# modules/nixos/programs/steam.nix
# Steam client
#
# Uses programs.steam (not a bare package) so NixOS sets up the FHS
# runtime, 32-bit graphics driver support (hardware.graphics.enable32Bit),
# udev rules for controllers, and firewall openings — installing the
# `steam` package alone does none of this.

{ ... }:

{
  programs.steam = {
    enable = true;

    # Open ports for in-home streaming (Remote Play) and for hosting
    # Source dedicated servers to LAN clients.
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Steam Input / controller support (DualSense, Xbox, 8BitDo, etc.).
  hardware.steam-hardware.enable = true;
}
