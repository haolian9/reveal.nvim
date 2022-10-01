-- NB:
-- * command does NOT overwrite pre-existing user command

local cmd = vifm.plugin.require("command")

local M = {}

assert(vifm.cmds.add({
  name = "Hello",
  description = "greet",
  handler = cmd.greet,
  maxargs = -1,
}))

assert(vifm.cmds.add({
  name = "Probe",
  description = "probe what vifm provides",
  handler = cmd.probe,
  maxargs = -1,
}))

vifm.cmds.add({
  name = "OpenInNvim",
  description = "open file under cursor in nvim",
  handler = cmd.open,
  maxargs = 0,
})

vifm.addhandler({
  name = "run",
  handler = function(info)
    vifm.sb.quick("gotta")
  end,
})

return M
