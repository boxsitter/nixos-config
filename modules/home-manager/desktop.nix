# modules/home-manager/desktop.nix
# Desktop/laptop GUI configuration
# Adds GUI programs to core config

{ ... }:

{
  imports = [
    ./programs/kitty.nix
  ];

  # GUI environment variables
  home.sessionVariables = {
    XCURSOR_SIZE = "14";
  };
}
