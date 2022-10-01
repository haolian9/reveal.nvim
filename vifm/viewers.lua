return function(require)
  local inspect = require("inspect")
  local root = "/tmp/1000-vifm-plugins/"
  local path = string.format("%s/%s", root, "viewers.log")

  local function show(info)
    vifm.sb.quick("!viewers.show")
    local file = assert(io.open(path, "a"))
    file:write(inspect(info))
    file:close()
  end

  return {
    show = show,
  }
end
