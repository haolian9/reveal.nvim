-- possible ways to communicating between nvim and vifm
-- * shares anony pipe between parent nvim and child vifm
-- * shares named pipe
-- * read from specific file
-- * read from vifm.stderr
--   * stdout is not suitable for communication
--   * stderr has not been used by vifm

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

  -- reusable resources
  bufnr = nil,
  win_id = nil,
  job = nil,
  ticker = nil,
  fifo = nil,

  ---@param self table
  is_buf_valid = function(self)
    return self.bufnr ~= nil and api.nvim_buf_is_valid(self.bufnr)
  end,

  ---@param self table
  reset = function(self)
    -- todo: handle errors

    log.debug("reseting state")

    vim.fn.chanclose(self.job)
    self.job = nil

    api.nvim_buf_delete(self.bufnr, { force = true })
    self.bufnr = nil

    self.ticker:stop()
    self.ticker:close()
    self.ticker = nil

    uv.fs_unlink(self.fifo_path)
  end,

  ---@param self table
  close_win = function(self)
    log.debug("closing win")
    api.nvim_win_close(self.win_id, true)
    self.win_id = nil
  end,
}

local function setup()
  if state.inited then return end

  state.inited = true
end

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
  setup()

  state.win_id = create_canvas(api.nvim_get_current_win())

  api.nvim_create_autocmd("WinLeave", {
    once = true,
    callback = function()
      state:close_win()
    end,
  })

  if state.ticker == nil then
    state.fifo = unsafe.FIFO(facts.fifo_path)
    state.ticker = uv.new_timer()
    state.ticker:start(0, facts.repeat_interval, function()
      local out = state.fifo.read_nowait()
      if out == false then return end
      state.ticker:stop()
      state.ticker:close()
      state.ticker = nil
      if out == "" then return log.err("reveal.fifo has been closed unexpectly") end
      vim.schedule(function()
        log.debug("vifm output: %s", out)
        state:close_win()
        -- todo: support multiple selection
        callback({ out })
      end)
    end)
  end

  -- todo: check job is alive?
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
        state:reset()
        if status ~= 0 then return log.err("vifm exit abnormally") end
        state:close_win()
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
