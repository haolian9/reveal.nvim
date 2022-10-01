local api = vim.api

-- {ns: namespace, root: str}
local state = nil

local function setup()
  if state ~= nil then return end

  state = {}
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

  local vifm = vim.fn.termopen({ "vifm", "--choose-files", "-", "--choose-dir", "-", root, root, "-c", "only" }, {
    on_exit = function(job_id, status, event)
      _, _ = job_id, event
      if status ~= 0 then return jellyfish.err("vifm exit abnormally") end
      local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
      api.nvim_win_close(win_id, true)
      callback(lines)
    end,
    stdout_buffered = false,
    stderr_buffered = false,
  })

  api.nvim_create_autocmd("WinLeave", {
    buffer = bufnr,
    callback = function()
      if vim.fn.jobwait({ vifm }, 0) == -1 then vim.fn.jobstop(vifm) end
    end,
  })

  api.nvim_cmd({ cmd = "startinsert" }, {})
end

return function()
  setup()
  main(handle_selection)
end
