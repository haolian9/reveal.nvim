---@type file*
local fifo
do
  local path = os.getenv("NVIM_PIPE")
  if path == nil then return {} end

  fifo = assert(io.open(path, "a"))
  -- stylua: ignore
  vifm.events.listen({ event = "app.exit", handler = function() fifo:close() end })
end

-- maybe: leftabove, rightbelow ... modifiers
local NvimOpenCmd = {
  edit = "edit",
  vsplit = "vsplit",
  split = "split",
  tabedit = "tabedit",
}

local function sendto_nvim(open_cmd, full_path)
  local ok, err = pcall(function()
    assert(NvimOpenCmd[open_cmd])
    fifo:write(string.format("%s %s\n\n", open_cmd, full_path))
    fifo:flush()
  end)
  if not ok then vifm.sb.error(err) end
end

assert(vifm.addhandler({
  name = "open",
  handler = function(info)
    sendto_nvim(NvimOpenCmd.edit, string.format("%s/%s", info.entry.location, info.entry.name))
  end,
}))

assert(vifm.cmds.add({
  name = "openinnvim",
  handler = function(info)
    local open_cmd = info.args
    if open_cmd == "" then open_cmd = NvimOpenCmd.edit end
    local full_path = vifm.expand("%d/%c")
    sendto_nvim(open_cmd, full_path)
  end,
  minargs = 0,
  maxargs = 1,
}))

do
  local function make_rhs(open_cmd)
    return function(info)
      _ = info
      local full_path = vifm.expand("%d/%c")
      sendto_nvim(open_cmd, full_path)
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
