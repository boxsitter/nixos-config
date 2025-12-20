# modules/nixos/services/tailscale.nix
# Tailscale VPN configuration

{ config, ... }:

{
  services.tailscale.enable = true;
  
  # Open Tailscale port
  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
  
  # Auto-connect on boot (requires auth key setup)
  # To authenticate headless server:
  # 1. Generate reusable auth key: https://login.tailscale.com/admin/settings/keys
  # 2. On server: sudo tailscale up --authkey=tskey-auth-xxxxx
  # After first auth, it will persist across reboots
}
