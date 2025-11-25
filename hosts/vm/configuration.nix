# ./hosts/vm/configuration.nix
# VirtualBox VM with Hyprland desktop

{ config, pkgs, ... }:

{
  imports = [
    # Hardware and system modules
    ./hardware-configuration.nix
    ../../modules/nixos/common.nix
    ../../modules/nixos/boot/grub.nix
    ../../modules/nixos/hardware/virtualbox.nix
    ../../modules/nixos/gui/hyprland.nix
    
    # Package imports
    ../../modules/nixos/packages/cli.nix
    ../../modules/nixos/packages/gui.nix
  ];

  # Set the flavor system-wide for Catppuccin modules
  catppuccin.flavor = "macchiato";

  # Hostname for VM
  networking.hostName = "nixos-vm";

  # 1Password GUI for VM
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "leyton" ];
  };

  # Enable SSH for remote rebuilds from host
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  networking.firewall.allowedTCPPorts = [ 22 ];

  system.stateVersion = "24.11";
}
