-- Dithered history chart for CPU and memory, rendered to a PNG.
local dither = require("helpers.dither")

local Chart = {}
Chart.__index = Chart

-- cols x rows dither cells on a canvas `height` cells tall with `pad_left`/`pad_right` margins.
-- Values at or above `warm_at` (0-1) use the rust tones.
local function new(opts)
  local self = setmetatable({
    cols = opts.cols or 44,
    rows = opts.rows or 20,
    warm_at = opts.warm_at or 0.6,
    canvas = { cell = opts.cell, height = opts.height, pad_left = opts.pad_left, pad_right = opts.pad_right, nudge = opts.nudge },
    values = {},
  }, Chart)
  self.width = (opts.pad_left or 0) + self.cols + (opts.pad_right or 0)
  return self
end

function Chart:push(value)
  self.values[#self.values + 1] = math.max(0, math.min(1, value))
  while #self.values > self.cols do table.remove(self.values, 1) end
end

-- History survives reloads as one number per line.
function Chart:save(path)
  local f = io.open(path, "w")
  if not f then return end
  for _, v in ipairs(self.values) do f:write(string.format("%.3f\n", v)) end
  f:close()
end

function Chart:load(path)
  local f = io.open(path, "r")
  if not f then return end
  for line in f:lines() do
    local v = tonumber(line)
    if v then self:push(v) end
  end
  f:close()
end

-- Cell grid: tops[x] is the row of the value edge (0 = top) for each column.
function Chart:cells()
  local grid, tops = {}, {}
  local first = self.cols - #self.values
  for x = 0, self.cols - 1 do
    local v = self.values[x - first + 1]
    if v then tops[x] = (self.rows - 1) - math.floor(v * (self.rows - 1) + 0.5) end
  end
  for y = 0, self.rows - 1 do
    local row = {}
    for x = 0, self.cols - 1 do
      local t, color = tops[x], dither.CLEAR
      if not t then
        -- No history yet: a dotted baseline keeps the chart's full width visible.
        if y == self.rows - 1 and x % 2 == 0 then color = dither.NAVY end
      else
        local tone = dither.TONES[self.values[x - first + 1] >= self.warm_at and "warm" or "cool"]
        -- Step edge: also light the cells between this top and the previous column's.
        local prev = tops[x - 1] or t
        if y == t or (prev < t and y >= prev and y < t) then
          color = tone.edge
        elseif y > t then
          color = dither.fill(tone, (y - t) / math.max(1, (self.rows - 1) - t), x, y)
        end
      end
      row[x] = color
    end
    grid[y] = row
  end
  return grid
end

function Chart:render(path)
  dither.write_png(path, self:cells(), self.cols, self.rows, self.canvas)
end

return { new = new }
