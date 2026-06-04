local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local battery_percent = sbar.add("item", "widgets.battery.percent", {
  position = "right",
  icon = { drawing = false },
  label = {
    string = "--%",
    font = { family = settings.font.numbers, size = 10.0 },
    padding_left = settings.group_paddings + settings.inner_padding,
    padding_right = settings.paddings + settings.inner_padding,
  },
  update_freq = 180,
})

local battery_icon = sbar.add("item", "widgets.battery.icon", {
  position = "right",
  padding_left = 0,
  icon = {
    font = {
      style = settings.font.style_map["Regular"],
      size = 13.0,
    },
    padding_left = 0,
    padding_right = settings.group_paddings + settings.inner_padding,
  },
  label = { drawing = false },
  popup = { align = "center" }
})

local remaining_time = sbar.add("item", {
  position = "popup." .. battery_icon.name,
  icon = {
    string = "Time remaining:",
    width = 100,
    align = "left"
  },
  label = {
    string = "??:??h",
    width = 100,
    align = "right"
  },
})


battery_percent:subscribe({"routine", "power_source_change", "system_woke"}, function()
  sbar.exec("pmset -g batt", function(batt_info)
    local icon = "!"
    local label = "?"

    local found, _, charge = batt_info:find("(%d+)%%")
    if found then
      charge = tonumber(charge)
      label = charge .. "%"
    end

    local color = colors.green
    local charging, _, _ = batt_info:find("AC Power")

    if charging then
      icon = icons.battery.charging
    else
      if found and charge > 80 then
        icon = icons.battery._100
      elseif found and charge > 60 then
        icon = icons.battery._75
      elseif found and charge > 40 then
        icon = icons.battery._50
      elseif found and charge > 20 then
        icon = icons.battery._25
        color = colors.orange
      else
        icon = icons.battery._0
        color = colors.red
      end
    end

    local lead = ""
    if found and charge < 10 then
      lead = "0"
    end

    battery_percent:set({
      label = { string = lead .. label, color = color },
    })
    battery_icon:set({
      icon = { string = icon, color = color }
    })
  end)
end)

battery_percent:subscribe("mouse.clicked", function(env)
  local drawing = battery_icon:query().popup.drawing
  battery_icon:set( { popup = { drawing = "toggle" } })

  if drawing == "off" then
    sbar.exec("pmset -g batt", function(batt_info)
      local found, _, remaining = batt_info:find(" (%d+:%d+) remaining")
      local label = found and remaining .. "h" or "No estimate"
      remaining_time:set( { label = label })
    end)
  end
end)

sbar.add("bracket", "widgets.battery.bracket", {
  battery_percent.name,
  battery_icon.name
}, {
  background = {
    color = colors.bg1,
    border_width = 0,
    border_color = colors.bg2,
  }
})

sbar.add("item", "widgets.battery.padding", {
  position = "right",
  width = settings.group_paddings
})
