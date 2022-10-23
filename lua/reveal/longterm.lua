local api = vim.api
local uv = vim.loop

local log = require("reveal.Logger")("reveal", vim.log.levels.DEBUG)
local unsafe = require("reveal.unsafe")

local facts = (function()
  local fifo_path = string.format("%s/%s", vim.fn.stdpath("run"), "reveal.fifo")
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
    local ok, errmsg, err = uv.fs_unlink(facts.fifo_path)
    if ok == nil and err ~= "ENOENT" then log.err(errmsg) end
  end,

  ---@param self table
  close_win = function(self)
    api.nvim_win_close(self.win_id, true)
    self.win_id = nil
  end,
}

local function create_canvas(host_win_id)
  if not state:is_buf_valid() then state.bufnr = api.nvim_create_buf(false, true) end
  local bufnr = state.bufnr

  local win_id
  do
    local host_win_width = api.nvim_win_get_width(host_win_id)
    local host_win_height = api.nvim_win_get_height(host_win_id)

    local width = math.floor(host_win_width * 0.8)
    local height = math.floor(host_win_height * 0.8)
    local row = math.floor(host_win_height * 0.1)
    local col = math.floor(host_win_width * 0.1)

    -- stylua: ignore
    win_id = api.nvim_open_win(bufnr, true, {
      relative = 'win', style = 'minimal', border = 'single',
      width = width, height = height, row = row, col = col,
    })
    api.nvim_win_set_hl_ns(win_id, facts.ns)
  end

  return win_id
end

---@param lines table
local function default_selection_handler(lines)
  log.debug("reveal.nvim handling %s", vim.inspect(lines))
  local file = lines[1]
  if file == "" then return end
  -- only open first selected file
  -- todo: custom open cmd
  -- todo: remember last accessed dir
  log.debug("editing %s", file)
  api.nvim_cmd({ cmd = "edit", args = { file } }, {})
end

---@return table
local function default_vifm_cmd()
  local root = vim.fn.expand("%:p:h")
  return { "vifm", root, root, "-c", "only" }
end

local function open(vifm_cmd_fn, callback)
  state.win_id = create_canvas(api.nvim_get_current_win())

  api.nvim_create_autocmd("WinLeave", {
    once = true,
    callback = function()
      state:close_win()
      state:clear_ticker()
    end,
  })

  if state.ticker == nil then
    if state.fifo == nil then state.fifo = unsafe.FIFO(facts.fifo_path) end
    state.ticker = uv.new_timer()
    state.ticker:start(0, facts.repeat_interval, function()
      local out = state.fifo.read_nowait()
      -- no output from vifm proc
      if out == false then return end

      vim.schedule(function()
        state:close_win()
        state:clear_ticker()
      end)

      if out == "" then return log.err("reveal.fifo has been closed unexpectly") end
      vim.schedule(function()
        log.debug("vifm output: %s", out)
        -- todo: support multiple selection
        callback({ out })
      end)
    end)
  end

  if state.job == nil then
    local cmd
    do
      cmd = vifm_cmd_fn()
      table.insert(cmd, "-c")
      table.insert(cmd, "filetype * #nvim#open")
    end

    state.job = vim.fn.termopen(cmd, {
      env = { NVIM_PIPE = facts.fifo_path },
      on_exit = function(job_id, status, event)
        _, _ = job_id, event
        vim.schedule(function()
          state:close_win()
          state:reset_term()
          state:clear_ticker()
          state:reset_fifo()
        end)
        if status ~= 0 then return log.err("vifm exit abnormally") end
      end,
      stdout_buffered = false,
      stderr_buffered = false,
    })
  end

  api.nvim_cmd({ cmd = "startinsert" }, {})
end

return function(vifm_cmd, selection_handler)
  if vifm_cmd then
    assert(type(vifm_cmd) == "function")
  else
    vifm_cmd = default_vifm_cmd
  end

  open(vifm_cmd, selection_handler or default_selection_handler)
end
