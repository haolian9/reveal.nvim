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
  local function rm(event) send_to_nvim(event.isdir and "rmdir" or "rm", event.path) end
  local function mv(event) send_to_nvim(event.isdir and "mvdir" or "mv", event.path, event.target) end

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

local NvimOpenMode = {
  inplace = "edit-inplace",
  right = "edit-right",
  below = "edit-below",
  tab = "edit-tab",
}

assert(vifm.addhandler({
  name = "open",
  handler = function(info)
    local fpath = string.format("%s/%s", info.entry.location, info.entry.name)
    send_to_nvim(NvimOpenMode.inplace, fpath)
  end,
}))

assert(vifm.cmds.add({
  name = "openinnvim",
  handler = function(info)
    local open_mode = info.args
    if open_mode == "" then
      open_mode = NvimOpenMode.inplace
    else
      assert(NvimOpenMode[open_mode])
    end

    local full_path = vifm.expand("%d/%c")
    send_to_nvim(open_mode, full_path)
  end,
  minargs = 0,
  maxargs = 1,
}))

do
  local function make_rhs(open_mode)
    return function(info)
      _ = info
      local full_path = vifm.expand("%d/%c")
      send_to_nvim(open_mode, full_path)
    end
  end

  local defns = {
    ["<cr>"] = NvimOpenMode.inplace,
    ["<c-o>"] = NvimOpenMode.below,
    -- for lhs <c-/>
    ["<c-_>"] = NvimOpenMode.right,
    -- for lhs <c-/> encoded by CSI u
    ["<esc>[47;5u"] = NvimOpenMode.right,
    ["<c-t>"] = NvimOpenMode.tab,
  }

  for lhs, open_cmd in pairs(defns) do
    assert(vifm.keys.add({ shortcut = lhs, modes = { "normal" }, handler = make_rhs(open_cmd), description = "[reveal] open a file in nvim" }))
  end
end

do
  local function handler() send_to_nvim("hide") end
  assert(vifm.keys.add({ shortcut = "<space>.", modes = { "normal" }, handler = handler, description = "[reveal] hide vifm" }))
  --NB: <c-z> works not in tmux
  assert(vifm.keys.add({ shortcut = [[<c-z>]], modes = { "normal" }, handler = handler, description = "[reveal] hide vifm" }))
end

-- vifm always expects a table returned from a plugin/init.lua
return {}
