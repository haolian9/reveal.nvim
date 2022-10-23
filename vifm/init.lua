-- NB:
-- * command does NOT overwrite pre-existing user command

-- awaiting https://github.com/vifm/vifm/issues/827
local shared = {
  vifm = vifm,
  require = vifm.plugin.require,
}

local openers = vifm.plugin.require("openers")(shared)

vifm.addhandler({
  name = "open",
  handler = openers.open,
})

if false then
  local viewers = require("viewers")(shared)
  local vicmd = require("vicmd")(shared)
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
end

-- vifm always expects a table returned from a plugin/init.lua
return {}
