# tests/eval/boot-loaders.nix
#
# Bootloader modules can't easily be VM-tested (a QEMU test VM uses its
# own kernel/initrd, not the bootloader the module installs). What we
# *can* do cheaply is evaluate each bootloader module against a synthetic
# stub config and assert the resulting boot.loader.* tree matches what
# we expect.
#
# This catches: typos in attribute paths, accidentally enabling both
# loaders, defaults drifting under us, and host-level overrides taking
# effect (e.g. configurationLimit, gfxmodeEfi).

{ pkgs, self, inputs, lib }:

let
  # Evaluate a single module path on top of a minimal NixOS skeleton, and
  # return its resulting `config` attrset.
  evalModule = modulePath: (lib.evalModules {
    modules = [
      "${inputs.nixpkgs}/nixos/modules/misc/nixpkgs.nix"
      "${inputs.nixpkgs}/nixos/modules/system/boot/loader/loader.nix"
      "${inputs.nixpkgs}/nixos/modules/system/boot/loader/grub/grub.nix"
      "${inputs.nixpkgs}/nixos/modules/system/boot/loader/systemd-boot/systemd-boot.nix"
      "${inputs.nixpkgs}/nixos/modules/system/boot/loader/efi.nix"
      modulePath
      ({ ... }: {
        nixpkgs.hostPlatform = "x86_64-linux";
        # The loader modules expect these to exist.
        _module.check = false;
      })
    ];
  }).config;

  systemdBoot = evalModule ../../modules/nixos/boot/systemd-boot.nix;
  grub        = evalModule ../../modules/nixos/boot/grub.nix;

  assertions = [
    # systemd-boot module
    { check = systemdBoot.boot.loader.systemd-boot.enable;
      msg = "systemd-boot.nix: systemd-boot should be enabled"; }
    { check = systemdBoot.boot.loader.systemd-boot.consoleMode == "auto";
      msg = "systemd-boot.nix: consoleMode should be 'auto'"; }
    { check = systemdBoot.boot.loader.efi.canTouchEfiVariables;
      msg = "systemd-boot.nix: canTouchEfiVariables should be true"; }
    { check = systemdBoot.boot.loader.timeout == 3;
      msg = "systemd-boot.nix: timeout should be 3 seconds"; }

    # grub module
    { check = grub.boot.loader.grub.enable;
      msg = "grub.nix: grub should be enabled"; }
    { check = grub.boot.loader.grub.efiSupport;
      msg = "grub.nix: efiSupport should be true"; }
    { check = grub.boot.loader.grub.useOSProber;
      msg = "grub.nix: useOSProber should be true (dual-boot)"; }
    { check = grub.boot.loader.grub.device == "nodev";
      msg = "grub.nix: device should be 'nodev' for EFI"; }
    { check = grub.boot.loader.grub.configurationLimit == 10;
      msg = "grub.nix: configurationLimit should be 10"; }
    { check = grub.boot.loader.grub.default == "saved";
      msg = "grub.nix: default should be 'saved' (remember last boot)"; }
    { check = grub.boot.loader.grub.gfxmodeEfi == "auto";
      msg = "grub.nix: gfxmodeEfi should be 'auto'"; }
    { check = grub.boot.loader.efi.canTouchEfiVariables;
      msg = "grub.nix: canTouchEfiVariables should be true"; }
    { check = grub.boot.loader.timeout == 5;
      msg = "grub.nix: default timeout should be 5"; }

    # Cross-cutting: hosts pick exactly one bootloader.
    { check = self.nixosConfigurations.desktop.config.boot.loader.grub.enable
           && !self.nixosConfigurations.desktop.config.boot.loader.systemd-boot.enable;
      msg = "desktop: must use grub, not systemd-boot"; }
    { check = self.nixosConfigurations.laptop.config.boot.loader.grub.enable
           && !self.nixosConfigurations.laptop.config.boot.loader.systemd-boot.enable;
      msg = "laptop: must use grub, not systemd-boot"; }
    { check = self.nixosConfigurations.server.config.boot.loader.systemd-boot.enable
           && !self.nixosConfigurations.server.config.boot.loader.grub.enable;
      msg = "server: must use systemd-boot, not grub"; }
  ];

  failed = lib.filter (a: !a.check) assertions;
in
if failed == [] then
  pkgs.runCommand "boot-loader-checks" {} ''
    echo "All ${toString (lib.length assertions)} bootloader assertions passed." > $out
  ''
else
  throw ''

    Bootloader assertion failures:
    ${lib.concatMapStringsSep "\n" (a: "  - ${a.msg}") failed}
  ''
