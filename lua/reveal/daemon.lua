local api = vim.api
local uv = vim.loop

local log = require("reveal.Logger")("reveal", vim.log.levels.DEBUG)
local unsafe = require("reveal.unsafe")

local facts = (function()
  local fifo_path = string.format("%s/%s.%d", vim.fn.stdpath("run"), "nvim.reveal", uv.getpid())
  log.debug("fifo_path=%s", fifo_path)

  local ns = api.nvim_create_namespace("reveal.nvim")
  api.nvim_set_hl(ns, "NormalFloat", { default = true })
  api.nvim_set_hl(ns, "FloatBorder", { default = true })

  return {
    ns = ns,
    fifo_path = fifo_path,
    repeat_interval = 50,
  }
end)()

local state = {
  inited = false,

  win_id = nil,

  -- persistent resources
  bufnr = nil,
  job = nil,
  ticker = nil,
  fifo = nil,

  ---@param self table
  is_buf_valid = function(self)
    return self.bufnr ~= nil and api.nvim_buf_is_valid(self.bufnr)
  end,

  ---@param self table
  is_win_valid = function(self)
    return self.win_id ~= nil and api.nvim_win_is_valid(self.win_id)
  end,

  ---@param self table
  reset_term = function(self)
    assert(not self:is_win_valid(), "win should be closed before resetting term.{job,bufnr}")

    if self.job ~= nil then
      vim.fn.chanclose(self.job)
      self.job = nil
    end

    if self.bufnr ~= nil then
      api.nvim_buf_delete(self.bufnr, { force = true })
      self.bufnr = nil
    end
  end,

  ---@param self table
  clear_ticker = function(self)
    if self.ticker == nil then return end
    self.ticker:stop()
    self.ticker:close()
    self.ticker = nil
  end,

  ---@param self table
  reset_fifo = function(self)
    assert(self.ticker == nil, "ticker should be closed before restting fifo")
    if self.fifo == nil then return end
    self.fifo.close()
    self.fifo = nil
    local ok, errmsg, err = uv.fs_unlink(facts.fifo_path)
    if ok == nil and err ~= "ENOENT" then log.err(errmsg) end
  end,

  ---@param self table
  close_win = function(self)
    api.nvim_win_close(self.win_id, true)
    self.win_id = nil
  end,
}

return function()
  local need_register_dismiss_keymaps = false

  -- term buf, should be reused
  if not state:is_buf_valid() then
    need_register_dismiss_keymaps = true
    state.bufnr = api.nvim_create_buf(false, true)
  end

  -- window, should be disposable
  do
    local host_win_id = api.nvim_get_current_win()
    local host_win_width = api.nvim_win_get_width(host_win_id)
    local host_win_height = api.nvim_win_get_height(host_win_id)

    local width = math.floor(host_win_width * 0.8)
    local height = math.floor(host_win_height * 0.8)
    local row = math.floor(host_win_height * 0.1)
    local col = math.floor(host_win_width * 0.1)

    -- stylua: ignore
    state.win_id = api.nvim_open_win(state.bufnr, true, {
      relative = 'win', style = 'minimal', border = 'single',
      width = width, height = height, row = row, col = col,
    })

    api.nvim_win_set_hl_ns(state.win_id, facts.ns)
    api.nvim_create_autocmd("WinLeave", {
      once = true,
      callback = function()
        state:close_win()
        state:clear_ticker()
      end,
    })
  end

  -- fifo, should be reused
  if state.fifo == nil then state.fifo = unsafe.FIFO(facts.fifo_path) end

  -- ticker, should be disposable
  do
    assert(state.ticker == nil)
    state.ticker = uv.new_timer()
    state.ticker:start(0, facts.repeat_interval, function()
      local file = state.fifo.read_nowait()
      -- no output from vifm proc
      if file == false then return end

      vim.schedule(function()
        state:close_win()
        -- todo: possible reuse by stop/continue?
        state:clear_ticker()

        if file == "" then return log.err("reveal.fifo has been closed unexpectly") end

        -- only open first selected file
        -- todo: support multiple selection
        -- todo: custom open cmd
        -- todo: remember last accessed dir
        log.debug("editing %s", file)
        api.nvim_cmd({ cmd = "edit", args = { file } }, {})
      end)
    end)
  end

  -- vifm proc, should be reused
  if state.job == nil then
    need_register_dismiss_keymaps = true

    local cmd
    do
      local root = vim.fn.expand("%:p:h")
      -- stylua: ignore
      cmd = {
        "vifm", root, root, "-c", "only",
        "-c", "filetype * #nvim#open",
        -- no footprints on vifminfo
        "-c", "set vifminfo="
      }
    end

    state.job = vim.fn.termopen(cmd, {
      env = { NVIM_PIPE = facts.fifo_path },
      on_exit = function(job_id, status, event)
        _, _ = job_id, event
        vim.schedule(function()
          state:close_win()
          state:clear_ticker()
          state:reset_term()
          state:reset_fifo()

          if status ~= 0 then return log.err("vifm exit abnormally") end
        end)
      end,
      stdout_buffered = false,
      stderr_buffered = false,
    })
  end

  -- keymap for dismiss the vifm window quickly
  -- CAUTION: fn.termopen will reset all the buffer-scoped keymaps
  if need_register_dismiss_keymaps then
    local function quit()
      assert(state:is_win_valid())
      state:close_win()
      state:clear_ticker()
    end

    vim.keymap.set("n", "q", quit, { buffer = state.bufnr, noremap = true })
    vim.keymap.set("n", "<esc>", quit, { buffer = state.bufnr, noremap = true })
    vim.keymap.set("n", "<c-[>", quit, { buffer = state.bufnr, noremap = true })
    vim.keymap.set("n", "<c-]>", quit, { buffer = state.bufnr, noremap = true })
  end

  api.nvim_cmd({ cmd = "startinsert" }, {})
end
