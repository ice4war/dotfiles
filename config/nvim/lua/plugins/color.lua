-- return {
--   "ellisonleao/gruvbox.nvim",
--   priority = 1000,
--   config = function()
--     require("gruvbox").setup({
--       style = "dark",
--       transparent_mode = true,
--     })
--     require("gruvbox").load()
--   end,
-- }
return {
  "navarasu/onedark.nvim",
  priority = 1000,
  config = function()
    require("onedark").setup({
      style = "dark",
      transparent = true,
    })
    require("onedark").load()
  end,
}
