local colors = require("colors")
local settings = require("settings")
local dither_gauge = require("helpers.dither_gauge")

-- Dithered battery gauge (20x11 body + 2-cell nub) instead of a battery glyph.
local gauge = dither_gauge({ name = "widgets.battery", w = 20, h = 11, nub = 2, canvas = { height = 26, pad_left = 6, nudge = 1 } })
local first_image, gauge_width = gauge(0, false, false)

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
  width = gauge_width,
  icon = { drawing = false },
  label = { drawing = false },
  background = {
    drawing = true,
    color = colors.transparent,
    image = { string = first_image, drawing = true, scale = 0.5, corner_radius = 0 },
  },
  popup = { align = "center" }
})

local remaining_time = sbar.add("item", {
  position = "popup." .. battery_icon.name,
  icon = {
    string = "Time remaining:",
    width = 145,
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
    local label = "?"

    local found, _, charge = batt_info:find("(%d+)%%")
    if found then
      charge = tonumber(charge)
      label = charge .. "%"
    end

    local charging = batt_info:find("AC Power") ~= nil
    -- Warm at 40% and below on battery, where the old glyph turned orange.
    local low = not charging and (not found or charge <= 40)
    local color = low and colors.navy_rust.orange or colors.navy_rust.blue

    local lead = ""
    if found and charge < 10 then
      lead = "0"
    end

    battery_percent:set({
      label = { string = lead .. label, color = color },
    })
    local image = gauge((charge or 0) / 100, low, charging)
    battery_icon:set({ background = { image = { string = image } } })
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
