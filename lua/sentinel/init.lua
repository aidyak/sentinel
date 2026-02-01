local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup("Sentinel", { clear = true })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    desc = "Check for unsaved buffers",
    callback = function()
      local ok, err = pcall(function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf)
            and vim.api.nvim_buf_is_loaded(buf)
            and vim.bo[buf].modified
          then
            local name = vim.api.nvim_buf_get_name(buf)
            if name ~= "" then
              print("Unsaved: " .. name)
            end
          end
        end
      end)
      if not ok then
        vim.notify("Sentinel error: " .. tostring(err), vim.log.levels.ERROR)
      end
    end,
  })
end

return M
