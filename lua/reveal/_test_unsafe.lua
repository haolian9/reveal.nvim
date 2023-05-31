local unsafe = require("reveal.unsafe")

local function test_1()
  -- local fpath = os.tmpname()
  local fpath = "/tmp/myvifmplugin.fifo"
  local fifo = unsafe.FIFO(fpath)
  print("xx", fifo.read())
end

test_1()
