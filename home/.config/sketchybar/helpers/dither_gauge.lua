-- Small dithered fill gauge (battery, disk), rendered to a PNG in the dither-chart style:
-- a 1px outline, fill dense at the left and thinning toward a crisp edge at the level.
local dither = require("helpers.dither")

-- 5x7 lightning bolt drawn over the fill while charging.
local BOLT = { "...##", "..##.", ".##..", "#####", "..##.", ".##..", "##..." }

-- opts: name (cache file stem), w, h (body cells), nub (battery terminal width, 0 for none),
-- canvas (write_png opts). Returns render(fraction, warm, charging) -> image path, canvas width.
return function(opts)
  local w, h, nub = opts.w or 20, opts.h or 11, opts.nub or 0
  local total = w + nub
  local next_path = dither.frames(opts.name)

  return function(fraction, warm, charging)
    local path = next_path()
    local tone = dither.TONES[warm and "warm" or "cool"]
    local inner_w = w - 4
    local level = math.floor(math.max(0, math.min(1, fraction)) * inner_w + 0.5)
    local grid = {}
    for y = 0, h - 1 do
      local row = {}
      for x = 0, total - 1 do
        local color = dither.CLEAR
        local corner = (x == 0 or x == w - 1) and (y == 0 or y == h - 1)
        if x < w then
          if (x == 0 or x == w - 1 or y == 0 or y == h - 1) and not corner then
            color = tone.edge
          elseif x >= 2 and x < w - 2 and y >= 2 and y < h - 2 then
            local fx = x - 2
            if fx == level - 1 then
              color = tone.edge
            elseif fx < level - 1 then
              color = dither.fill(tone, (level - 1 - fx) / math.max(1, level - 1), x, y)
            end
          end
        elseif y >= (h - 5) // 2 and y < (h - 5) // 2 + 5 then
          color = tone.edge
        end
        row[x] = color
      end
      grid[y] = row
    end
    if charging then
      local bx, by = (w - 5) // 2, (h - 7) // 2
      for dy, line in ipairs(BOLT) do
        for dx = 1, 5 do
          if line:sub(dx, dx) == "#" then grid[by + dy - 1][bx + dx - 1] = dither.PAPER end
        end
      end
    end
    return path, dither.write_png(path, grid, total, h, opts.canvas or {})
  end
end
