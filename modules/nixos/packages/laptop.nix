# modules/nixos/packages/laptop.nix
# Laptop-specific tools (power management, brightness, etc.)

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    brightnessctl
    powertop
    acpi
  ];
}
