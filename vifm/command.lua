-- ref: /usr/share/vifm/vim-doc/doc/vifm-lua.txt
--
-- NB:
-- * no globals: package

local M = {}

local count = 0
function M.greet(info)
  count = count + 1
  local what = "world"
  if info.args ~= "" then what = info.args end
  local kind_words = string.format("Hello, %s! (%d)", what, count)
  vifm.sb.info(kind_words)
end

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

local open_state = nil

local function open_init()
  if open_state ~= nil then return end

  open_state = {}

  do
    local path = "/tmp/1000-vifm-plugins/playground.log"
    open_state.log = assert(io.open(path, "a"))
  end

  do
    local path = "/tmp/1000-vifm-plugins/playground.fifo"
    open_state.fifo = assert(io.open(path, "a"))
  end
end

function M.open()
  open_init()

  local view = vifm.currview()
  local entry = view:entry(view.currententry)
  local msg = string.format("entry:name=%s, location=%s, type=%s\n", entry.name, entry.location, entry.type)
  open_state.log:write(msg)
  open_state.fifo:write(msg)

  open_state.log:flush()
  open_state.fifo:flush()
end

return M
