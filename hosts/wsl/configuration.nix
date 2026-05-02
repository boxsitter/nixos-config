# ./hosts/wsl/configuration.nix
# WSL2 configuration - no GUI, no bootloader

{ pkgs, ... }:

{
  imports = [
    ../../modules/nixos/core.nix
    ../../modules/nixos/secrets.nix
    # ../../modules/nixos/services/samba-client.nix  # TODO: Re-enable after running setup script
    ../../modules/nixos/services/server/immich.nix
    ../../modules/nixos/services/tailscale.nix
  ];

  wsl = {
    enable = true;
    defaultUser = "leyton";
    startMenuLaunchers = true;
    wslConf.automount.root = "/mnt";
    wslConf.interop.appendWindowsPath = false;
    wslConf.user.default = "leyton";
  };

  programs.nix-ld.enable = true;
  networking.hostName = "nixos-wsl";
  networking.networkmanager.enable = false;
  security.polkit.enable = false;
  services.chrony.enable = pkgs.lib.mkForce false;

  # Increase inotify limits for JetBrains IDEs (file watcher) in WSL
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 512;
  };

  console.font = null;
  console.packages = [ ];
}
