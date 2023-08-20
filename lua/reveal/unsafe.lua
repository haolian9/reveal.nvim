local M = {}

local ffi = require("ffi")

local dictlib = require("infra.dictlib")

ffi.cdef([[
  int open(const char* pathname, int flags);
  int close(int fd);
  int read(int fd, void* buf, unsigned int count);
  int mkfifo(const char * pathname, int mode);
]])

local C = ffi.C

local function oct(lit) return tonumber(lit, 8) end

-- flag&modes for open
-- see /usr/include/asm-generic/fcntl.h
local O = {
  -- flags
  APPEND = oct("02000"),
  CLOEXEC = oct("02000000"),
  EXCL = oct("0200"),
  NONBLOCK = oct("04000"),
  TRUNC = oct("01000"),
  -- modes
  RDONLY = oct("00"),
  WRONLY = oct("01"),
  RDWR = oct("02"),
}

-- see /usr/include/fcntl.h
local S = {
  -- owner
  IRWXU = oct("00700"),
  IRUSR = oct("00400"),
  IWUSR = oct("00200"),
  IXUSR = oct("00100"),
  -- group
  IRWXG = oct("00070"),
  IRGRP = oct("00040"),
  IWGRP = oct("00020"),
  IXGRP = oct("00010"),
  -- others
  IRWXO = oct("00007"),
  IROTH = oct("00004"),
  IWOTH = oct("00002"),
  IXOTH = oct("00001"),
}

-- see /usr/include/asm-generic/errno-base.h
local ERRNO = {
  EPERM = 1,
  ENOENT = 2,
  EINTR = 4,
  EBADFD = 9,
  EAGAIN = 11,
  EACCES = 13,
  EEXIST = 17,
  ENOTDIR = 20,
  EISDIR = 21,
  EINVAL = 22,
  EPIPE = 32,
  EWOULDBLOCK = 11,
}

local guard_errno
do
  local errno_text = dictlib.flipped(ERRNO)

  -- NB: assume `rv == -1` indicates an error
  ---@param safe_false_errnos table
  ---@return number|false
  function guard_errno(rv, safe_false_errnos)
    if rv ~= -1 then return rv end
    local errno = ffi.errno()
    if safe_false_errnos ~= nil then
      for _, v in ipairs(safe_false_errnos) do
        if errno == v then return false end
      end
    end
    error(errno_text[errno] or errno)
  end
end

do
  ---@class reveal.unsafe.FIFO
  ---@field private fd userdata
  ---@field private bufsize integer
  ---@field private buffer userdata
  local Prototype = {}

  Prototype.__index = Prototype

  function Prototype:close() guard_errno(C.close(self.fd)) end

  do
    local safe_errnos = { ERRNO.EWOULDBLOCK }
    ---when returning: false=closed, ""=unavailable
    ---@return string|false
    function Prototype:read_nowait()
      local nbytes = guard_errno(C.read(self.fd, self.buffer, self.bufsize), safe_errnos)
      if nbytes then
        if nbytes == 0 then return "" end
        return ffi.string(self.buffer, nbytes)
      end
      return false
    end
  end

  ---@param fpath string
  ---@param bufsize? number
  ---@param exists_ok? boolean @nil=true
  ---@retur reveal.unsafe.FIFO
  function M.FIFO(fpath, bufsize, exists_ok)
    bufsize = bufsize or 4096
    if exists_ok == nil then exists_ok = true end

    guard_errno(C.mkfifo(fpath, bit.bor(S.IRUSR, S.IWUSR)), { ERRNO.EEXIST })
    local fd = guard_errno(C.open(fpath, bit.bor(O.RDWR, O.NONBLOCK)))

    local buffer = ffi.new("uint8_t[?]", bufsize)

    return setmetatable({ fd = fd, bufsize = bufsize, buffer = buffer }, Prototype)
  end
end

return M
