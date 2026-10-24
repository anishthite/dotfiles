-- Shared pieces of the dithered bar widgets: the navy-rust-v2 icon palette, a 4x4 Bayer
-- threshold and a pure-Lua PNG writer. Style after dither-kit: fills are sparse at the value
-- edge and dense at the base, and the edge itself is a crisp 1px line.

local BAYER = {
  { 0, 8, 2, 10 },
  { 12, 4, 14, 6 },
  { 3, 11, 1, 9 },
  { 15, 7, 13, 5 },
}

local function rgba(hex)
  return string.char((hex >> 16) & 0xff, (hex >> 8) & 0xff, hex & 0xff, 0xff)
end

local M = {
  dir = (os.getenv("CONFIG_DIR") or os.getenv("HOME") .. "/.config/sketchybar") .. "/cache/dither",
  INK = rgba(0x141C2E), PAPER = rgba(0xF1E7D3), NAVY = rgba(0x2E4468), BLUE = rgba(0x7F9BBE),
  RUST = rgba(0x8A3B1C), ORANGE = rgba(0xD98A5C), CLEAR = string.char(0, 0, 0, 0),
}
os.execute("mkdir -p '" .. M.dir .. "'")

-- Paths alternate between two files so SketchyBar reloads the image on every set.
function M.frames(name)
  local frame = 0
  return function()
    frame = 1 - frame
    return string.format("%s/%s_%d.png", M.dir, name, frame)
  end
end

M.TONES = {
  cool = { edge = M.BLUE, fill = M.NAVY },
  warm = { edge = M.ORANGE, fill = M.RUST },
}

-- density 0 at the value edge .. 1 at the base: lit cells take the fill tone, the rest ink.
function M.fill(tone, density, x, y)
  return density > (BAYER[(y & 3) + 1][(x & 3) + 1] + 0.5) / 16 and tone.fill or M.INK
end

local CRC = {}
for i = 0, 255 do
  local c = i
  for _ = 1, 8 do
    c = (c & 1 == 1) and (0xEDB88320 ~ (c >> 1)) or (c >> 1)
  end
  CRC[i] = c
end

local function crc32(s)
  local c = 0xFFFFFFFF
  for i = 1, #s do
    c = CRC[(c ~ s:byte(i)) & 0xff] ~ (c >> 8)
  end
  return c ~ 0xFFFFFFFF
end

local function adler32(s)
  local a, b = 1, 0
  for i = 1, #s do
    a = (a + s:byte(i)) % 65521
    b = (b + a) % 65521
  end
  return (b << 16) | a
end

local function chunk(kind, data)
  return string.pack(">I4", #data) .. kind .. data .. string.pack(">I4", crc32(kind .. data))
end

-- Uncompressed (stored) deflate: tiny images, so size doesn't matter but speed does.
local function zlib_stored(raw)
  local out = { "\x78\x01" }
  local pos, n = 1, #raw
  repeat
    local len = math.min(65535, n - pos + 1)
    local final = (pos + len > n) and 1 or 0
    out[#out + 1] = string.pack("<BI2I2", final, len, len ~ 0xffff) .. raw:sub(pos, pos + len - 1)
    pos = pos + len
  until pos > n
  out[#out + 1] = string.pack(">I4", adler32(raw))
  return table.concat(out)
end

-- Write grid[y][x] (0-based, w x h cells of RGBA strings) as a PNG. Each cell is `cell` pixels
-- (2 = one point on Retina at image scale 0.5). The canvas adds `pad_left`/`pad_right` empty
-- cells and is `height` cells tall with the grid centred, so the image carries its own spacing.
-- `nudge` moves the grid down that many pixels. 14pt Berkeley Mono digits centre 0.5pt below the
-- bar's midline: an even-height grid already lands there (images snap to whole pixels), an
-- odd-height one like the 11-row gauge needs a 1px nudge.
function M.write_png(path, grid, w, h, opts)
  local c, pad_left, pad_right = opts.cell or 2, opts.pad_left or 0, opts.pad_right or 0
  local height = math.max(opts.height or h, h)
  local width = pad_left + w + pad_right
  local top = (height - h) // 2
  local empty, left, right = M.CLEAR:rep(width * c), M.CLEAR:rep(pad_left * c), M.CLEAR:rep(pad_right * c)
  local raw = {}
  for y = 0, height - 1 do
    local line = empty
    local gy = y - top
    if gy >= 0 and gy < h then
      local cells = { left }
      for x = 0, w - 1 do cells[#cells + 1] = grid[gy][x]:rep(c) end
      cells[#cells + 1] = right
      line = table.concat(cells)
    end
    for _ = 1, c do raw[#raw + 1] = "\0" .. line end
  end
  for _ = 1, opts.nudge or 0 do
    table.remove(raw)
    table.insert(raw, 1, "\0" .. empty)
  end
  local png = "\x89PNG\r\n\x1a\n"
    .. chunk("IHDR", string.pack(">I4I4BBBBB", width * c, height * c, 8, 6, 0, 0, 0))
    .. chunk("IDAT", zlib_stored(table.concat(raw)))
    .. chunk("IEND", "")
  local tmp = path .. ".tmp"
  local f = assert(io.open(tmp, "wb"))
  f:write(png)
  f:close()
  os.rename(tmp, path)
  return width
end

return M
