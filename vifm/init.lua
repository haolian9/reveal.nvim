-- NB:
-- * command does NOT overwrite pre-existing user command

local require = vifm.plugin.require
local cmds = vifm.plugin.require("cmds")(require)
local openers = vifm.plugin.require("openers")(require)
local viewers = vifm.plugin.require("viewers")(require)
local vicmd = vifm.plugin.require("vicmd")(vifm)

local M = {}

assert(vifm.cmds.add({
  name = "Probe",
  description = "probe what vifm provides",
  handler = cmds.probe,
  maxargs = -1,
}))

vifm.cmds.add({
  name = "OpenInNvim",
  description = "open file under cursor in nvim",
  handler = cmds.open,
  maxargs = 0,
})

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

return M
