---@type file*
local fifo
local send_to_nvim
do
  local path = os.getenv("NVIM_PIPE")
  if path == nil then return {} end

  fifo = assert(io.open(path, "a"))
  -- stylua: ignore
  vifm.events.listen({ event = "app.exit", handler = function() fifo:close() end })

  ---@param ... string
  send_to_nvim = function(...)
    fifo:write(table.concat({ ... }, "\0"))
    fifo:write("\n\n")
    fifo:flush()
  end
end

if os.getenv("NVIM_FS_SYNC") == "1" then
  local function rm(event)
    send_to_nvim(event.isdir and "rmdir" or "rm", event.path)
  end
  local function mv(event)
    send_to_nvim(event.isdir and "mvdir" or "mv", event.path, event.target)
  end

  vifm.events.listen({
    event = "app.fsop",
    ---@param event vifm.events.FsopEvent
    handler = function(event)
      if event.op == "move" then
        if event.totrash then
          rm(event)
        elseif event.fromtrash then
          -- pass
        else
          mv(event)
        end
      elseif event.op == "remove" then
        rm(event)
      end
    end,
  })
end

-- maybe: leftabove, rightbelow ... modifiers
local NvimOpenCmd = {
  edit = "edit",
  vsplit = "vsplit",
  split = "split",
  tabedit = "tabedit",
}

local function open_in_nvim(open_cmd, full_path)
  assert(NvimOpenCmd[open_cmd])
  send_to_nvim(open_cmd, full_path)
end

assert(vifm.addhandler({
  name = "open",
  handler = function(info)
    open_in_nvim(NvimOpenCmd.edit, string.format("%s/%s", info.entry.location, info.entry.name))
  end,
}))

assert(vifm.cmds.add({
  name = "openinnvim",
  handler = function(info)
    local open_cmd = info.args
    if open_cmd == "" then open_cmd = NvimOpenCmd.edit end
    local full_path = vifm.expand("%d/%c")
    open_in_nvim(open_cmd, full_path)
  end,
  minargs = 0,
  maxargs = 1,
}))

do
  local function make_rhs(open_cmd)
    return function(info)
      _ = info
      local full_path = vifm.expand("%d/%c")
      open_in_nvim(open_cmd, full_path)
    end
  end

  local defns = {
    ["<c-o>"] = NvimOpenCmd.split,
    -- for lhs <c-/>
    ["<c-_>"] = NvimOpenCmd.vsplit,
    -- for lhs <c-/> encoded by CSI u
    ["<esc>[47;5u"] = NvimOpenCmd.vsplit,
    ["<c-t>"] = NvimOpenCmd.tabedit,
  }

  for lhs, open_cmd in pairs(defns) do
    assert(vifm.keys.add({ shortcut = lhs, modes = { "normal" }, handler = make_rhs(open_cmd) }))
  end
end

-- vifm always expects a table returned from a plugin/init.lua
return {}
