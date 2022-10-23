-- NB:
-- * command does NOT overwrite pre-existing user command

-- stores vifm to share the same require between submods
-- awaiting https://github.com/vifm/vifm/issues/827
local require = (function()
  local _cached_mods = {}
  local primitive_require = vifm.plugin.require
  return function(name)
    if _cached_mods[name] == nil then _cached_mods[name] = primitive_require(name) end
    return _cached_mods[name]
  end
end)()

local shared = (function()
  return {
    vifm = vifm,
    -- i'm not sure if vifm has a cache for require, so i cache them here explicitly
    require = require,
  }
end)()

local openers = require("openers")(shared)
local viewers = require("viewers")(shared)
local vicmd = require("vicmd")(shared)

vifm.addhandler({
  name = "open",
  handler = openers.open,
})

vifm.addhandler({
  name = "view",
  handler = viewers.show,
})

vifm.addhandler({
  name = "vicmd",
  handler = function(info)
    vifm.sb.err(string.format("vicmd.action: %s", info.action))
    return vicmd(info)
  end,
})

-- vifm always expects a table returned from a plugin/init.lua
return {}
