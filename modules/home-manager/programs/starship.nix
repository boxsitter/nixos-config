# modules/home-manager/programs/starship.nix
# Starship prompt configuration

{ ... }:

{
  programs.starship = {
    enable = true;
    # Use the custom TOML configuration
  };

  # Reference the custom starship.toml dotfile
  xdg.configFile."starship.toml".source = ../dotfiles/starship.toml;
}
