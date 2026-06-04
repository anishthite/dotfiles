local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local mem = sbar.add("graph", "widgets.memory", 44, {
  position = "right",
  graph = { color = colors.blue },
  background = {
    height = 26,
    corner_radius = 8,
    color = colors.bg1,
    border_width = 0,
    drawing = true,
  },
  icon = {
    string = icons.memory or icons.cpu,
    color = colors.blue,
    font = { family = settings.font.numbers, size = 10.0, style = settings.font.style_map["Bold"] },
    align = "right",
    padding_left = 0,
    padding_right = 30,
    width = 0,
  },
  label = {
    string = "--%",
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
      size = 10.0,
    },
    align = "right",
    padding_right = settings.group_paddings + settings.inner_padding,
    width = 0,
  },
  update_freq = 5,
})

local function update_memory()
  local cmd = [[memory_pressure | awk '/System-wide memory free percentage/ {gsub("%","",$5); printf "%.0f", 100-$5}']]
  sbar.exec(cmd, function(usage)
    local used = tonumber(usage) or 0
    local color = colors.blue
    if used > 85 then color = colors.red
    elseif used > 70 then color = colors.orange
    elseif used > 50 then color = colors.yellow
    end
    mem:push({ used / 100.0 })
    mem:set({
      icon = { color = color },
      graph = { color = color },
      label = string.format("%d%%", used),
    })
  end)
end

mem:subscribe({ "routine", "forced", "system_woke" }, update_memory)
mem:subscribe("mouse.clicked", function() sbar.exec("open -a 'Activity Monitor'") end)
update_memory()

sbar.add("item", "widgets.memory.padding", {
  position = "right",
  width = settings.group_paddings,
})
