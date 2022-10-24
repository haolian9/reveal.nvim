-- NB:
-- * command does NOT overwrite pre-existing user command

-- todo: close
local fifo = (function()
  local fifo_path = vifm.expand("$NVIM_PIPE")
  assert(fifo_path ~= nil and fifo_path ~= "" and fifo_path ~= "$NVIM_PIPE")

  local file, err = io.open(fifo_path, "a")
  assert(file, err)

  return file
end)()

vifm.addhandler({
  name = "open",
  handler = function(info)
    fifo:write(string.format("%s/%s", info.entry.location, info.entry.name))
    fifo:flush()
  end,
})

-- vifm always expects a table returned from a plugin/init.lua
return {}
