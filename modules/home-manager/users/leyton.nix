# modules/home-manager/users/leyton.nix
# User identity for leyton - shared across all hosts

{ config, ... }:

{
  # User identity
  home = {
    username = "leyton";
    homeDirectory = "/home/leyton";
    stateVersion = "24.11";
  };

  # Declare standard XDG directories so GNOME Tracker, file managers,
  # and portals can locate them.
  # Fixes: localsearch-3: Unable to get XDG user directory path for &DOWNLOAD etc.
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    download   = "${config.home.homeDirectory}/Downloads";
    documents  = "${config.home.homeDirectory}/Documents";
    music      = "${config.home.homeDirectory}/Music";
    pictures   = "${config.home.homeDirectory}/Pictures";
    videos     = "${config.home.homeDirectory}/Videos";
    desktop    = "${config.home.homeDirectory}/Desktop";
    templates  = "${config.home.homeDirectory}/Templates";
    publicShare = "${config.home.homeDirectory}/Public";
  };
}
