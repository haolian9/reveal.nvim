local function noop(fmt, ...) end

local function log(level, min_level, opts)
  assert(level ~= nil and min_level ~= nil)
  if level < min_level then return noop end
  return function(fmt, ...)
    vim.notify(string.format(fmt, ...), level, opts)
  end
end

return function(name, min_level)
  assert(name and min_level)
  local opts = { source = name }

  return {
    debug = log(vim.log.levels.DEBUG, min_level, opts),
    err = log(vim.log.levels.ERROR, min_level, opts),
    info = log(vim.log.levels.INFO, min_level, opts),
  }
end
