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
    #../../modules/nixos/services/hyprland.nix
    ../../modules/nixos/programs/1password-gui.nix
    ../../modules/nixos/programs/steam.nix
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

  networking.hostName = "nixos-laptop";

  # Claude Desktop (community flake packaging Anthropic's official Linux build)
  programs.claude-desktop.enable = true;

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

  programs.nix-ld.enable = true;

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
