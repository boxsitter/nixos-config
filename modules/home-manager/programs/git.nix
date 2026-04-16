# modules/home-manager/programs/git.nix
# Git configuration

{ ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        email = "leyton.houck@gmail.com";
        name = "boxsitter";
      };
      core = {
        autocrlf = "input";  # Convert CRLF to LF on commit, keep LF on checkout
        eol = "lf";          # Always use LF in the working directory
      };
      credential.helper = "store";  # Store credentials on disk (or use "cache" for temporary)
    };
  };
}
