# hosts/mac/configuration.nix
# macOS system configuration using nix-darwin

{ ... }:

{
  # Enable Nix daemon
  services.nix-daemon.enable = true;

  # Enable SSH access
  programs.ssh.startAgent = true;

  # Configure Nix
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "@admin" ];
  };

  # Set hostname
  networking.hostName = "macos-mac-mini";

  # Used for backwards compatibility, please read changelog before changing
  system.stateVersion = 5;
}
