local opstr_iter = require("reveal.opstr_iter")

local function test_0()
  local ok, err = pcall(opstr_iter, "edit\0foo \0b ar")
  assert(not ok)
  assert(vim.endswith(err, "not a valid op str"))
end

local function test_1()
  local iter = opstr_iter("edit\0foo \0b ar\n\n")
  assert(iter() == "edit")
  assert(iter() == "foo ")
  assert(iter() == "b ar")
  assert(iter() == nil)
end

test_0()
test_1()
