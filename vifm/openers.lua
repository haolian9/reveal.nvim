return function(shared)
  vifm = shared.vifm

  local fifo_path = vifm.expand("$NVIM_PIPE")
  if fifo_path == nil or fifo_path == "" or fifo_path == "$NVIM_PIPE" then return {} end

  local fifo = assert(io.open(fifo_path, "a"))

  local function open(info)
    local msg = string.format("%s/%s", info.entry.location, info.entry.name)
    fifo:write(msg)
    fifo:flush()
  end

  return {
    open = open,
  }
end
