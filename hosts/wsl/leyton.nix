# hosts/wsl/leyton.nix
# User configuration for leyton on WSL

{ ... }:

{
  imports = [
    ../../modules/home-manager/users/leyton.nix
    ../../modules/home-manager/core.nix
  ];

  # Always start in home directory when WSL launches
  programs.fish.loginShellInit = ''
    if test "$PWD" != "$HOME"
      cd ~
    end
  '';

  # VS Code via Windows
  programs.fish.shellAliases = {
    code = "/mnt/c/Users/leyton/AppData/Local/Programs/'Microsoft VS Code'/bin/code";
  };
}
