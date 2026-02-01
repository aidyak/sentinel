local ok, err = pcall(function()
  require("sentinel").setup()
end)
if not ok then
  vim.notify("Sentinel failed to load: " .. tostring(err), vim.log.levels.ERROR)
end
