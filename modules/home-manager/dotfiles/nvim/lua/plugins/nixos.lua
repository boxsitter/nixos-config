-- NixOS adjustments for LazyVim.
--
-- Mason downloads prebuilt, dynamically-linked binaries that expect a standard
-- FHS layout, so they fail to run on NixOS. Instead we disable Mason entirely
-- and let nvim-lspconfig / conform pick the tools up from $PATH, where they are
-- put by `extraPackages` in modules/home-manager/programs/neovim.nix.
--
-- Adding a language means two edits: a server entry below, plus its package in
-- that Nix module.

return {
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  { "williamboman/mason.nvim", enabled = false },
  { "williamboman/mason-lspconfig.nvim", enabled = false },
  { "jay-babu/mason-nvim-dap.nvim", enabled = false },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lua_ls = {},
        nixd = {},
      },
    },
  },

  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        nix = { "nixfmt" },
      },
    },
  },

  {
    -- Parsers are compiled locally with gcc rather than fetched as binaries.
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "bash", "lua", "markdown", "markdown_inline", "nix", "vim", "vimdoc" },
    },
  },
}
