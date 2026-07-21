-- Match the Catppuccin Macchiato theme used across the rest of the system
-- (see catppuccin settings in modules/home-manager/core.nix).

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "macchiato",
      background = { dark = "macchiato" },
      integrations = {
        blink_cmp = true,
        gitsigns = true,
        mason = false,
        which_key = true,
      },
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
