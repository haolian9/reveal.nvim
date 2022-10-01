return function(vifm)
  local inspect = vifm.plugin.require("inspect")

  local root = "/tmp/1000-vifm-plugins"
  local path = string.format("%s/%s", root, "vicmd.log")
  local file = assert(io.open(path, "a"))

  local function open_help(info)
    vifm.sb.quick("!vi.open_help")
    file:write("[open_help] ")
    file:write(inspect(info))
    file:write("\n")
    file:flush()
    return true
  end

  local function edit_one(info)
    vifm.sb.quick("!vi.edit_one")
    file:write("[open_help] ")
    file:write(inspect(info))
    file:write("\n")
    file:flush()
    return true
  end

  local function edit_many(info)
    vifm.sb.quick("!vi.edit_many")
    file:write("[open_help] ")
    file:write(inspect(info))
    file:write("\n")
    file:flush()
    return true
  end

  local function edit_list(info)
    vifm.sb.quick("!vi.edit_list")
    file:write("[open_help] ")
    file:write(inspect(info))
    file:write("\n")
    file:flush()
    return true
  end

  local handlers = {
    ["open-help"] = open_help,
    ["edit-one"] = edit_one,
    ["edit_many"] = edit_many,
    ["edit_list"] = edit_list,
  }

  return function(info)
    local h = handlers[info.action]
    if h == nil then
      vifm.sb.error(string.format("unexpected action: %s", info.action))
      return { success = false }
    end
    return { success = h(info) }
  end
end
