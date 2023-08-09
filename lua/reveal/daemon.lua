local api = vim.api
local uv = vim.loop

local bufpath = require("infra.bufpath")
local bufrename = require("infra.bufrename")
local ex = require("infra.ex")
local fs = require("infra.fs")
local handyclosekeys = require("infra.handyclosekeys")
local jelly = require("infra.jellyfish")("reveal")
local popupgeo = require("infra.popupgeo")
local strlib = require("infra.strlib")

local opstr_iter = require("reveal.opstr_iter")
local unsafe = require("reveal.unsafe")

local facts = (function()
  local fifo_path = string.format("%s/%s.%d", vim.fn.stdpath("run"), "nvim.reveal", uv.getpid())
  jelly.debug("fifo_path=%s", fifo_path)

  local hl_ns
  do
    hl_ns = api.nvim_create_namespace("reveal.nvim")
    api.nvim_set_hl(hl_ns, "NormalFloat", { default = true })
    api.nvim_set_hl(hl_ns, "FloatBorder", { default = true })
  end

  local root = fs.resolve_plugin_root("reveal", "daemon.lua")

  return {
    hl_ns = hl_ns,
    fifo_path = fifo_path,
    repeat_interval = 50,
    vifm_rtp = fs.joinpath(root, "vifm"),
  }
end)()

---@class reveal.daemon.state
---@field winid? integer
---@field bufnr? integer
---@field job? integer @the vifm process
---@field ticker? integer @event loop
---@field fifo? reveal.unsafe.FIFO
local state = {}
do
  ---@param self reveal.daemon.state
  function state:reset_term()
    if self.winid and api.nvim_win_is_valid(self.winid) then error("win should be closed before resetting term.{job,bufnr}") end

    if self.job ~= nil then
      vim.fn.chanclose(self.job)
      self.job = nil
    end

    if self.bufnr ~= nil then
      api.nvim_buf_delete(self.bufnr, { force = true })
      self.bufnr = nil
    end
  end

  function state:clear_ticker()
    if self.ticker == nil then return end
    self.ticker:stop()
    self.ticker:close()
    self.ticker = nil
  end

  function state:reset_fifo()
    assert(self.ticker == nil, "ticker should be closed before restting fifo")
    if self.fifo == nil then return end
    self.fifo:close()
    self.fifo = nil
    local ok, errmsg, err = uv.fs_unlink(facts.fifo_path)
    if ok == nil and err ~= "ENOENT" then return jelly.err(errmsg) end
  end

  function state:close_win()
    if self.winid == nil then return end
    api.nvim_win_close(self.winid, true)
    self.winid = nil
  end
end

local handle_op, handle_delayed_ops
do
  ---@type {[string]: fun(op: string, args: string[])}
  local ops = {}
  --NB: it's an undefined behavior when ops conflict
  local delayed_ops = {}
  do
    do
      ---@param op string
      ---@param args string[]
      local function open(op, args)
        assert(#args >= 1)
        vim.schedule(function()
          state:close_win()
          state:clear_ticker()
          ex(op, args[1])
        end)
      end

      ops.edit = open
      ops.tabedit = open
      ops.split = open
      ops.vsplit = open
    end

    local function delay(handler) table.insert(delayed_ops, handler) end

    ops.mv = function(op, args)
      assert(op == "mv")
      local src, dst = unpack(args)
      assert(src and dst)
      vim.schedule(function()
        local bufnr = vim.fn.bufnr(src)
        if bufnr == -1 then return jelly.debug("file has not be opened") end
        delay(function() bufrename(bufnr, dst) end)
      end)
    end

    do
      local function renamed_bufs_under_dir(src, dst)
        local function resolve(bufnr)
          local abspath = bufpath.file(bufnr)
          if abspath == nil then return end
          if not strlib.startswith(abspath, src) then return end
          local relpath = string.sub(abspath, #src + 2)
          return string.format("%s/%s", dst, relpath)
        end

        local all = api.nvim_list_bufs()
        local offset = 1

        return function()
          while offset <= #all do
            local bufnr = all[offset]
            offset = offset + 1
            local newname = resolve(bufnr)
            if newname ~= nil then return { bufnr, newname } end
          end
        end
      end

      function ops.mvdir(op, args)
        assert(op == "mvdir")
        local src, dst = unpack(args)
        assert(src and dst)
        vim.schedule(function()
          for tuple in renamed_bufs_under_dir(src) do
            local bufnr, newname = unpack(tuple)
            delay(function() bufrename(bufnr, newname) end)
          end
        end)
      end
    end

    do
      local function nop() end
      -- same as &autoread, we do not do bwipe
      ops.rm = nop
      ops.rmdir = nop
    end
  end

  handle_op = function(opstr)
    local iter = opstr_iter(opstr)
    local op = assert(iter(), "missing op")
    local handle = assert(ops[op], "no available handler")
    local args = {}
    for a in iter do
      table.insert(args, a)
    end

    -- vim.schedule needs to be call explicitly in handler
    handle(op, args)
  end

  --calls after vifm window closed
  --no need to wrapped in a vim.schedule
  handle_delayed_ops = function()
    local queue = delayed_ops
    jelly.debug("handling %s delayed ops", #queue)
    delayed_ops = {}
    for _, handle in ipairs(queue) do
      local ok, err = pcall(handle)
      -- no break here, keep going even if erred
      if not ok then jelly.err(err) end
    end
  end
end

---@param root? string only having effects on starting new vifm process
---@param enable_fs_sync? boolean @nil=false
return function(root, enable_fs_sync)
  root = root or vim.fn.expand("%:p:h")
  if enable_fs_sync == nil then enable_fs_sync = false end

  local need_register_dismiss_keymaps = false

  do -- term buf, should be reused
    if state.bufnr == nil then
      need_register_dismiss_keymaps = true
      state.bufnr = api.nvim_create_buf(false, true) --no ephemeral here
    end
    assert(api.nvim_buf_is_valid(state.bufnr))
  end

  do -- window, disposable
    assert(state.winid == nil)
    local width, height, row, col = popupgeo.editor_central(0.8, 0.8)

    -- stylua: ignore
    state.winid = api.nvim_open_win(state.bufnr, true, {
      relative = 'editor', style = 'minimal', border = 'single',
      width = width, height = height, row = row, col = col,
    })

    api.nvim_win_set_hl_ns(state.winid, facts.hl_ns)

    api.nvim_create_autocmd("winclosed", {
      buffer = state.bufnr,
      once = true,
      callback = function()
        state.winid = nil
        state:clear_ticker()
        handle_delayed_ops()
      end,
    })
  end

  do -- fifo, should be reused
    if state.fifo == nil then state.fifo = unsafe.FIFO(facts.fifo_path) end
  end

  do -- ticker, disposable
    assert(state.ticker == nil)
    state.ticker = uv.new_timer()
    state.ticker:start(0, facts.repeat_interval, function()
      local opstr = state.fifo:read_nowait()
      -- no output from vifm proc
      if opstr == false then return end
      assert(opstr ~= "", "fifo has been closed unexpectly")
      handle_op(opstr)
    end)
  end

  -- vifm proc, should be reused
  if state.job == nil then
    need_register_dismiss_keymaps = true

    -- stylua: ignore
    local cmd = {
      "vifm",
      --essential options to be functional
      "--plugins-dir", facts.vifm_rtp,
      "-c", "filetype * #reveal#open",
      --only one pane
      "-c", "only",
      --avoid footprints on vifminfo
      "-c", "set vifminfo=",
      root, root,
    }

    state.job = vim.fn.termopen(cmd, {
      env = { NVIM_PIPE = facts.fifo_path, NVIM_FS_SYNC = enable_fs_sync and 1 or 0 },
      on_exit = function(_, status, _)
        vim.schedule(function()
          state:close_win()
          state:clear_ticker()
          state:reset_term()
          state:reset_fifo()

          if status ~= 0 then return jelly.err("vifm exit abnormally") end
        end)
      end,
      stdout_buffered = false,
      stderr_buffered = false,
    })

    --CAUTION: termopen will set the bufname
    bufrename(state.bufnr, string.format("vifm://"))
  end

  --CAUTION: fn.termopen will reset all the buffer-scoped keymaps
  if need_register_dismiss_keymaps then handyclosekeys(state.bufnr) end

  ex("startinsert")
end
