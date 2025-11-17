# ./flake.nix
{
  description = "NixOS configurations for desktop, VM, and WSL";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    catppuccin.url = "github:catppuccin/nix";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations = {
      # Desktop with NVIDIA RTX 5080 and Hyprland
      desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          inputs.catppuccin.nixosModules.catppuccin
          ./hosts/desktop/configuration.nix
        ];
      };

      # VirtualBox VM with Hyprland
      vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          inputs.catppuccin.nixosModules.catppuccin
          ./hosts/vm/configuration.nix
        ];
      };

      # WSL2 - no GUI, minimal config
      wsl = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          inputs.catppuccin.nixosModules.catppuccin
          ./hosts/wsl/configuration.nix
        ];
      };

      # Legacy alias for backward compatibility
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          inputs.catppuccin.nixosModules.catppuccin
          ./hosts/desktop/configuration.nix
        ];
      };
    };
  };
}