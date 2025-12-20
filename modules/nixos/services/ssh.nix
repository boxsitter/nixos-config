# modules/nixos/services/ssh.nix
# OpenSSH server configuration

{ ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Only allow SSH through Tailscale (tightens security)
  # If you need SSH from outside Tailscale, remove this
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 22 ];
}
