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

  environment.sessionVariables = {
    # WSL exposes the GPU via /dev/dxg and mounts the Windows NVIDIA driver
    # userspace libs (libcuda.so.1, libnvidia-ml.so.1, ...) at /usr/lib/wsl/lib.
    # NixOS doesn't put that on the loader path, so CUDA apps and nvidia-smi
    # can't find those libs and torch.cuda.is_available() returns false.
    # Adding it here makes the GPU work in every shell (RTX 5080 passthrough).
    LD_LIBRARY_PATH = [ "/usr/lib/wsl/lib" ];

    # Foreign (non-Nix) Python interpreters — e.g. uv's standalone CPython —
    # are compiled to look for CA certs at /etc/ssl/cert.pem, which doesn't
    # exist on NixOS (the bundle lives at /etc/ssl/certs/ca-bundle.crt). Without
    # this, stdlib ssl / urllib fail with CERTIFICATE_VERIFY_FAILED on every
    # HTTPS request. Pointing SSL_CERT_FILE at the real bundle fixes it globally.
    SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
  };

  console.font = null;
  console.packages = [ ];
}
