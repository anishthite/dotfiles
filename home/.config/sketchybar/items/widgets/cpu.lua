local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

sbar.exec("killall cpu_load >/dev/null; $CONFIG_DIR/helpers/event_providers/cpu_load/bin/cpu_load cpu_update 2.0")

local cpu = sbar.add("graph", "widgets.cpu", 44, {
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
    string = icons.cpu,
    color = colors.blue,
    font = { family = settings.font.numbers, size = 10.0, style = settings.font.style_map["Bold"] },
    align = "right",
    padding_left = 0,
    padding_right = 30,  -- sits just left of the "--%" label
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
})

cpu:subscribe("cpu_update", function(env)
  local load = tonumber(env.total_load) or 0
  cpu:push({ load / 100. })
  local color = colors.blue
  if load > 80 then color = colors.red
  elseif load > 60 then color = colors.orange
  elseif load > 30 then color = colors.yellow
  end
  cpu:set({
    icon = { color = color },
    graph = { color = color },
    label = env.total_load .. "%",
  })
end)

cpu:subscribe("mouse.clicked", function() sbar.exec("open -a 'Activity Monitor'") end)

sbar.add("item", "widgets.cpu.padding", {
  position = "right",
  width = settings.group_paddings,
})
