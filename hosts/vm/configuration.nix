# ./hosts/vm/configuration.nix
# VirtualBox VM with Hyprland desktop

{ config, pkgs, ... }:

{
  imports = [
    # Hardware detection
    ./hardware.nix
    
    # Shared modules
    ../../modules/nixos/core.nix
    ../../modules/nixos/shell/fish.nix
    ../../modules/nixos/shell/kitty.nix
    
    # VM-specific
    ../../modules/nixos/boot/grub.nix
    ../../modules/nixos/hardware/virtualbox.nix
    ../../modules/nixos/gui/hyprland.nix
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

  # VM-specific packages
  environment.systemPackages = with pkgs; [
    vscode
  ];

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
