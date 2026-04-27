# ./hosts/laptop/configuration.nix
# Laptop system with NVIDIA RTX 3050 Mobile, optimized for battery life and portability

{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/secrets.nix
    ../../modules/nixos/boot/grub.nix
    ../../modules/nixos/hardware/nvidia-laptop.nix
    ../../modules/nixos/hardware/dual-boot.nix
    ../../modules/nixos/hardware/intel-wifi.nix
    ../../modules/nixos/services/gnome.nix
    # ../../modules/nixos/services/samba-client.nix  # TODO: Re-enable after running setup script
    ../../modules/nixos/programs/1password-gui.nix
  ];

  environment.systemPackages = with pkgs; [
    brightnessctl
    powertop
    acpi
  ];

  # The XPS 15 9530 has no physical PS/2 port. Blacklisting psmouse
  # prevents it from claiming the Synaptics I2C touchpad (VEN_06CB)
  # as a generic PS/2 mouse if the ACPI/I2C stack ever initialises
  # out of order (e.g. after a BIOS update changes _OSI behaviour).
  boot.blacklistedKernelModules = [ "psmouse" ];

  # Use PSR1 (Panel Self Refresh level 1) instead of PSR2 to fix the black
  # screen bug on the XPS 15 9530. The i915 driver enables PSR2 by default
  # on Raptor Lake-H, but PSR2's selective update path has a known bug where
  # the panel enters a bad self-refresh state and goes black ~5-10 seconds
  # after the display becomes static (recovers on any input).
  # PSR1 retains most of the panel power savings without the PSR2 state
  # machine bugs. Use enable_psr=0 only if PSR1 still causes issues.
  boot.kernelParams = [ "i915.enable_psr=1" ];

  networking.hostName = "nixos-laptop";

  nixpkgs = {
    config = {
      allowUnfree = true;
      nvidia.acceptLicense = true;
    };
  };

  # `auto-cpufreq` conflicts with `power-profiles-daemon`.
  # Prefer `auto-cpufreq` for laptops since it applies cpu/battery tuning
  # automatically without relying on desktop power profile integration.
  services.power-profiles-daemon.enable = false;

  services.thermald.enable = true;
  services.auto-cpufreq = {
    enable = true;
    settings = {
      battery = {
        governor = "powersave";
        turbo = "auto";
      };
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };
  };

  # Docker
  virtualisation.docker.enable = true;

  services.ratbagd.enable = true;

  # Explicitly configure libinput so the touchpad is recognised as a touchpad
  # (not a generic mouse) and the keyboard behaves correctly.
  services.libinput = {
    enable = true;
    touchpad = {
      tapping            = true;          # tap-to-click
      naturalScrolling   = true;
      scrollMethod       = "twofinger";   # explicit two-finger scroll
      clickMethod        = "buttonareas"; # reliable bottom-zone left/right click
      disableWhileTyping = true;
      accelProfile       = "adaptive";
      sendEventsMode     = "enabled";     # ensure events are never suppressed
    };
  };

  # Pin keyboard layout so it survives reboots.
  # NOTE: do NOT add acpi_osi= (blank) to kernelParams to suppress WiFi
  # ACPI log spam. It prevents the BIOS from exposing the I2C touchpad.
  # Use boot.consoleLogLevel = 3 instead if log spam becomes an issue.
  services.xserver.xkb = {
    layout = "us";
  };
}
