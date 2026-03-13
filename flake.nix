# ./flake.nix
{
  description = "NixOS configurations for desktop, laptop, and WSL";

  # Optional: Binary cache for faster builds
  nixConfig = {
    extra-substituters = [ "https://playit-nixos-module.cachix.org" ];
    extra-trusted-public-keys = [ "playit-nixos-module.cachix.org-1:22hBXWXBbd/7o1cOnh+p0hpFUVk9lPdRLX3p5YSfRz4=" ];
    # Allow hydra-server to fetch dependencies during build
    sandbox = "relaxed";
    warn-dirty = false;  # Disable dirty git tree warnings
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      url = "github:catppuccin/nix";
    };
    playit-nixos-module = {
      url = "github:pedorich-n/playit-nixos-module";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations = {
      # Desktop with NVIDIA RTX 5080 and GNOME
      desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          inputs.sops-nix.nixosModules.sops
          ./hosts/desktop/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.leyton = import ./hosts/desktop/leyton.nix;
            home-manager.extraSpecialArgs = { inherit inputs; catppuccin = inputs.catppuccin; };
            home-manager.backupFileExtension = "backup";
          }
        ];
      };

      # Laptop with NVIDIA RTX 3050 Mobile and GNOME
      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          inputs.sops-nix.nixosModules.sops
          ./hosts/laptop/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.leyton = import ./hosts/laptop/leyton.nix;
            home-manager.extraSpecialArgs = { inherit inputs; catppuccin = inputs.catppuccin; };
            home-manager.backupFileExtension = "backup";
          }
        ];
      };

      # WSL2 - no GUI, minimal config
      wsl = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          inputs.nixos-wsl.nixosModules.default
          inputs.sops-nix.nixosModules.sops
          ./hosts/wsl/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.leyton = import ./hosts/wsl/leyton.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.backupFileExtension = "backup";
          }
        ];
      };

      # Headless server with SSH and Tailscale
      server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          inputs.playit-nixos-module.nixosModules.default
          inputs.nix-minecraft.nixosModules.minecraft-servers
          inputs.sops-nix.nixosModules.sops
          ./hosts/server/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.leyton = import ./hosts/server/leyton.nix;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.backupFileExtension = "backup";
            nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];
          }
        ];
      };
    };

    # macOS configuration using nix-darwin
    darwinConfigurations = {
      mac = inputs.darwin.lib.darwinSystem {
        system = "aarch64-darwin"; # Change to "x86_64-darwin" for Intel Macs
        modules = [
          ./hosts/mac/configuration.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.leyton = import ./hosts/mac/leyton.nix;
            home-manager.backupFileExtension = "backup";
          }
        ];
      };
    };
  };
}