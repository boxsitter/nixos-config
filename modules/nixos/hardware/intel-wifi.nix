# modules/nixos/hardware/intel-wifi.nix
# Intel WiFi driver configuration

{ ... }:

{
  # Intel WiFi driver
  boot.kernelModules = [ "iwlwifi" ];
  
  # Enable firmware
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;
}
