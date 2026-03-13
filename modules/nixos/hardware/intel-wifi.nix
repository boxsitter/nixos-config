# modules/nixos/hardware/intel-wifi.nix
# Intel WiFi driver configuration

{ ... }:

{
  # Intel WiFi driver
  boot.kernelModules = [ "iwlwifi" ];
  
  # Workaround for iwlwifi PNVM timeout and async errors
  boot.kernelParams = [
    "iwlwifi.disable_11ax=Y"     # Disable WiFi 6 to avoid PNVM timeout
  ];
  
  # Enable firmware
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;
}
