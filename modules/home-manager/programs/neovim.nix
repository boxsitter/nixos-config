# modules/home-manager/programs/neovim.nix
# Neovim with the LazyVim distribution.
#
# Nix provides the editor and every external tool LazyVim shells out to
# (compilers, LSP servers, formatters, CLI helpers); lazy.nvim still manages the
# plugins themselves, cloning them into ~/.local/share/nvim on first launch.
#
# The config lives in ../dotfiles/nvim and is symlinked file-by-file rather than
# as a whole directory, so ~/.config/nvim stays a writable directory and
# lazy.nvim can keep its lazy-lock.json there.

{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Leave plugins/extraConfig empty — home-manager would generate its own
    # init.lua and collide with the LazyVim one linked below.
    extraPackages = with pkgs; [
      # Build tooling for tree-sitter parsers and native plugin builds.
      # stdenv.cc rather than gcc so this stays valid on the darwin host, where
      # it resolves to clang.
      stdenv.cc
      gnumake
      tree-sitter

      # LazyVim expects these on $PATH
      git
      lazygit
      ripgrep
      fd
      curl
      wget
      unzip
      gzip

      # Runtimes several plugins and language servers need
      nodejs_22
      python3

      # Language servers (Mason is disabled — see lua/plugins/nixos.lua)
      lua-language-server
      nixd

      # Formatters
      stylua
      nixfmt-rfc-style
    ];
  };

  xdg.configFile = {
    "nvim/init.lua".source = ../dotfiles/nvim/init.lua;

    "nvim/lua/config/lazy.lua".source = ../dotfiles/nvim/lua/config/lazy.lua;
    "nvim/lua/config/options.lua".source = ../dotfiles/nvim/lua/config/options.lua;
    "nvim/lua/config/keymaps.lua".source = ../dotfiles/nvim/lua/config/keymaps.lua;
    "nvim/lua/config/autocmds.lua".source = ../dotfiles/nvim/lua/config/autocmds.lua;

    "nvim/lua/plugins/nixos.lua".source = ../dotfiles/nvim/lua/plugins/nixos.lua;
    "nvim/lua/plugins/catppuccin.lua".source = ../dotfiles/nvim/lua/plugins/catppuccin.lua;
  };
}
