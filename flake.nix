# ./flake.nix
{
  description = "NixOS configurations for desktop, VM, and WSL";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    catppuccin.url = "github:catppuccin/nix";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations = {
      # Desktop with NVIDIA RTX 5080 and Hyprland
      desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          inputs.catppuccin.nixosModules.catppuccin
          ./hosts/desktop/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.leyton = import ./home/leyton/desktop.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };

      # VirtualBox VM with Hyprland
      vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          inputs.catppuccin.nixosModules.catppuccin
          ./hosts/vm/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.leyton = import ./home/leyton/vm.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };

      # WSL2 - no GUI, minimal config
      wsl = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          inputs.nixos-wsl.nixosModules.default
          inputs.catppuccin.nixosModules.catppuccin
          ./hosts/wsl/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.leyton = import ./home/leyton/wsl.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
            # Disable systemd integration in WSL (no D-Bus)
            systemd.services.home-manager-leyton.enable = false;
          }
        ];
      };
    };
  };
}