local M = {}

function M.setup()
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      -- 全バッファをチェック
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
          local name = vim.api.nvim_buf_get_name(buf)
          if name ~= "" then
            print("Unsaved: " .. name)
          end
        end
      end
    end,
  })
end

return M
