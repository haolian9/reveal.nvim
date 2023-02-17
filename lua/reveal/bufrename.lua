local ok, mod = pcall(require, "infra.bufrename")
if ok then return mod end

local api = vim.api

--credits: @lewis6991, https://github.com/neovim/neovim/issues/20349#issuecomment-1257998865
---@param bufnr number
---@param full_name string
---@param short_name string?
return function(bufnr, full_name, short_name)
  _ = short_name
  if api.nvim_buf_get_name(bufnr) == full_name then return end
  api.nvim_buf_set_name(bufnr, full_name)
  do
    local altnr = api.nvim_buf_call(bufnr, function()
      return vim.fn.bufnr("#")
    end)
    if altnr ~= bufnr and altnr ~= -1 then api.nvim_buf_delete(altnr, { force = true }) end
  end
end
