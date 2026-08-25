# ./hosts/wsl/configuration.nix
# WSL2 configuration - no GUI, no bootloader

{ pkgs, lib, ... }:

{
  imports = [
    ../../modules/nixos/core.nix
    ../../modules/nixos/secrets.nix
    ../../modules/nixos/services/server/immich.nix
  ];

  wsl = {
    enable = true;
    defaultUser = "leyton";
    startMenuLaunchers = true;
    wslConf.automount.root = "/mnt";
    wslConf.interop.appendWindowsPath = false;
    wslConf.user.default = "leyton";
  };

  networking.hostName = "nixos-wsl";
  networking.networkmanager.enable = false;
  security.polkit.enable = false;
  services.chrony.enable = pkgs.lib.mkForce false;

  # Increase inotify limits for JetBrains IDEs (file watcher) in WSL
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 512;
  };
  
  # SSH is not needed on WSL — access is via Windows Terminal.
  # Without this, sshd fails on every boot because WSL doesn't run
  # the host-key generation trigger, causing 5 noisy restart attempts.
  services.openssh.enable = lib.mkForce false;

  # WSL kills the VM without a clean shutdown on every exit, which
  # always leaves the on-disk journal in a "corrupted" state. Using
  # volatile (RAM-only) journal avoids the rename-and-replace noise
  # on every startup and eliminates the slight I/O overhead.
  services.journald.extraConfig = "Storage=volatile";

  # mandb re-indexes every man page on each boot — 4 seconds and
  # 147 MB of disk reads for a dev environment that rarely needs it.
  # Man pages still work; the database is just rebuilt on first use.
  systemd.services.mandb.wantedBy = lib.mkForce [];

  console.font = null;
  console.packages = [ ];
}
