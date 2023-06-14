local strlib = require("infra.strlib")

local sep = "\0"
local ends = "\n\n"

---@param str string
return function(str)
  assert(strlib.endswith(str, ends), "not a valid op str")

  local start_at = 1
  return function()
    if start_at > #str then return end
    local sep_at = strlib.find(str, sep, start_at)
    local part
    if sep_at == nil then
      -- excludes the ends
      part = string.sub(str, start_at, -#ends - 1)
      start_at = #str + 1
    else
      part = string.sub(str, start_at, sep_at - 1)
      start_at = sep_at + #sep
    end
    return part
  end
end
