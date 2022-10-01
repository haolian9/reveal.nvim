return function(require)
  local inspect = require("inspect")
  local root = "/tmp/1000-vifm-plugins/"
  local path = string.format("%s/%s", root, "openers.log")
  local file = assert(io.open(path, "a"))

  local function open(info)
    vifm.sb.quick("!openers.open")
    file:write(inspect(info))
    file:flush()
  end

  return {
    open = open,
  }
end
