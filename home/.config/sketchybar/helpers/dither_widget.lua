-- A dithered history chart chip with its percent overlaid on the right, for CPU and memory.
local colors = require("colors")
local settings = require("settings")
local dither = require("helpers.dither")
local dither_chart = require("helpers.dither_chart")


-- Adds the item and returns it with update(fraction, text).
return function(name, opts)
  local chart = dither_chart.new(opts)
  local history = string.format("%s/%s.history", dither.dir, name)
  chart:load(history)
  local next_path = dither.frames(name)
  -- Start from saved history so the image always has a file and a reload doesn't blank the chart.
  local first = next_path()
  chart:render(first)

  local item = sbar.add("item", name, {
    position = "right",
    width = chart.width,
    icon = { drawing = false },
    label = {
      string = "--%",
      color = colors.navy_rust.paper,
      font = {
        family = settings.font.numbers,
        style = settings.font.style_map["Bold"],
        size = 10.0,
      },
      align = "right",
      padding_left = 0,
      padding_right = 6,
      -- The number sits on the dither: cream text with a 1px ink shadow reads over both tones.
      shadow = { drawing = true, color = colors.navy_rust.ink, angle = 270, distance = 1 },
    },
    background = {
      drawing = true,
      color = colors.bg1,
      height = 26,
      corner_radius = 8,
      image = { string = first, drawing = true, scale = 0.5, corner_radius = 0 },
    },
    update_freq = opts.update_freq,
  })

  item:subscribe("mouse.clicked", function() sbar.exec("open -a 'Activity Monitor'") end)

  local function update(fraction, text)
    chart:push(fraction)
    chart:save(history)
    local path = next_path()
    chart:render(path)
    item:set({
      background = { image = { string = path } },
      label = {
        string = text,
        color = fraction >= chart.warm_at and colors.navy_rust.orange or colors.navy_rust.paper,
      },
    })
  end

  return item, update
end
