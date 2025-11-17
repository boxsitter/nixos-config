# ./flake.nix
{
  description = "NixOS configurations for desktop, VM, and WSL";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    catppuccin.url = "github:catppuccin/nix";
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
          config
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
        config = import ./hosts/vm/hardware-configuration.nix;
        config
        specialArgs = { inherit inputs; };
        modules = [
          inputs.catppuccin.nixosModules.catppuccin
          ./hosts/vm/configuration.nix
          config
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
          inputs.catppuccin.nixosModules.catppuccin
          ./hosts/wsl/configuration.nix
          config
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.leyton = import ./home/leyton/wsl.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
    };
  };
}