return function(shared)
  vifm = shared.vifm

  local fifo
  do
    local fifo_path = vifm.expand("$NVIM_PIPE")
    assert(fifo_path ~= nil)
    fifo = assert(io.open(fifo_path, "a"))
  end

  local function open(info)
    local msg = string.format("%s/%s", info.entry.location, info.entry.name)
    fifo:write(msg)
    fifo:flush()
  end

  return {
    open = open,
  }
end
