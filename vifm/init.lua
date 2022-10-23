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

-- vifm always expects a table returned from a plugin/init.lua
return {}
