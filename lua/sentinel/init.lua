local M = {}

function M.hello()
  if vim.bo.modified then
    print("Modified file: " .. vim.fn.expand("%"))
  end
end

return M
