# modules/nixos/services/ssh.nix
# SSH configuration with Tailscale integration

{ ... }:

{
  # Use Tailscale SSH (handles auth automatically)
  services.tailscale.useRoutingFeatures = "both";
  
  # Traditional SSH as fallback
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Only allow SSH through Tailscale
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 22 ];
}
