local uv = vim.loop
local api = vim.api

local log = require("vifm.Logger")("vifm.oneshot", "Debug")
local cqueues = require("/srv/playground/vifm.nvim/vendor/cqueues/src/5.1/cqueues")

-- {inited: true|nil, ns: namespace, root: str}
local state = {}

local function setup()
  if state.inited ~= nil then return end

  state = {}
  state.inited = true
  state.ns = api.nvim_create_namespace("awesome.vifm")
  api.nvim_set_hl(state.ns, "NormalFloat", { default = true })
  api.nvim_set_hl(state.ns, "FloatBorder", { default = true })
end

local function create_canvas(host_win_id)
  local bufnr
  do
    bufnr = api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
  end

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
    api.nvim_win_set_hl_ns(win_id, state.ns)
  end

  return bufnr, win_id
end

---@param lines table
local function handle_selection(lines)
  -- * when select one, expects 2 lines: selected file, last accessed directory
  -- * when select none, expects 1 line: last accessed directory
  local sufficient_num = 0
  for i = 1, #lines do
    if lines[i] == "" then break end
    sufficient_num = i
  end
  assert(sufficient_num > 0)
  state.root = lines[#lines]
  if sufficient_num == 1 then return end
  -- only open first selected file
  -- todo: custom open cmd
  -- todo: remember last accessed dir
  api.nvim_cmd({ cmd = "edit", args = { lines[1] } }, {})
end

local function main(callback)
  local root = vim.fn.expand("%:p:h")
  local bufnr, win_id = create_canvas(api.nvim_get_current_win())

  -- local fds = uv.pipe({ nonblock = true }, { nonblock = true })
  -- local sender = uv.new_pipe()
  -- uv.pipe_open(sender, fds.read)
  -- local receiver = uv.new_pipe()
  -- uv.pipe_open(receiver, fds.write)
  -- vim.notify(string.format("sender=%d, writer=%d", fds.read, fds.write))

  local pipe_fpath
  do
    -- todo maybe stdpath('run')
    -- should be per-nvim-instance
    local root = "/tmp"
    pipe_fpath = string.format("%s/%s", root, "1000-vifm-nvim.fifo")
  end

  -- stylua: ignore
  local cmd = {
    "vifm",
    root, root,
    "-c", "filetype * #nvim#open_in_nvim",
    "-c", "only",
  }
  local vifm_job = vim.fn.termopen(cmd, {
    env = { NVIM_PIPE = pipe_fpath },
    on_exit = function(job_id, status, event)
      _, _ = job_id, event
      if status ~= 0 then return log.err("vifm exit abnormally") end
      local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
      api.nvim_win_close(win_id, true)
      if false then callback(lines) end
    end,
    stdout_buffered = false,
    stderr_buffered = false,
  })

  local pipe = io.open(pipe_fpath, "r")
  local ticker = uv.new_timer()
  ticker:start(250, 250, function()
    pipe:read()
  end)

  -- uv.read_start(receiver, function(err, data)
  --   assert(err ~= nil, err)
  --   vim.schedule(function()
  --     vim.notify(string.format("received: %s", data))
  --   end)
  -- end)

  api.nvim_create_autocmd("WinLeave", {
    buffer = bufnr,
    callback = function()
      if vim.fn.jobwait({ vifm_job }, 0) == -1 then vim.fn.jobstop(vifm_job) end
    end,
  })

  api.nvim_cmd({ cmd = "startinsert" }, {})
end

return function()
  setup()
  -- main(handle_selection)
  vim.notify(vim.inspect(cqueues))
end
