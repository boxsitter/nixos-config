# modules/home-manager/users/leyton.nix
# User identity for leyton - shared across all hosts

{ ... }:

{
  # User identity
  home = {
    username = "leyton";
    homeDirectory = "/home/leyton";
    stateVersion = "24.11";
  };
}
