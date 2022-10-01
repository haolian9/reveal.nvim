-- ref: /usr/share/vifm/vim-doc/doc/vifm-lua.txt
--
-- NB:
-- * no globals: package

return function(require)
  _ = require

  local M = {}
  function M.probe()
    local result = {}
    local function probe(mod, name)
      if mod == nil then return table.insert(result, string.format("%s: -", name)) end
      if type(mod) ~= "table" then return table.insert(result, string.format("%s:+%s", name, type(mod))) end
      local subkeys = {}
      for k, _ in pairs(mod) do
        table.insert(subkeys, k)
      end
      table.insert(result, string.format("%s:+#%d#%s", name, #mod, table.concat(subkeys, ",")))
    end

    probe(math, "math")
    probe(io, "io")
    probe(os, "os")

    vifm.sb.info(table.concat(result, "\n"))
  end

  local root = "/tmp/1000-vifm-plugins"
  local open_state = {}

  local function open_init()
    if open_state.log ~= nil then return end

    do
      local path = string.format("%s/%s", root, "cmds.log")
      open_state.log = assert(io.open(path, "a"))
    end

    -- do
    --   local path = string.format("%s/%s", root, "cmds.fifo")
    --   open_state.fifo = assert(io.open(path, "a"))
    -- end

  end

  function M.open()
    open_init()

    vifm.sb.info("!cmds.open")
    local view = vifm.currview()
    local entry = view:entry(view.currententry)
    local msg = string.format("entry:name=%s, location=%s, type=%s\n", entry.name, entry.location, entry.type)
    open_state.log:write(msg)
    open_state.log:flush()

    -- assert(string.sub(msg, #msg) == "\n", "msg for fifo must end with ln")
    -- open_state.fifo:write(msg)
    -- open_state.fifo:flush()
  end

  return M
end
