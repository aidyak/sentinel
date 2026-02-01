vim.api.nvim_create_user_command("Sentinel", function()
  require("sentinel").hello()
end, {})
