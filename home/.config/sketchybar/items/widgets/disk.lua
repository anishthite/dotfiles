local colors = require("colors")
local settings = require("settings")
local dither_gauge = require("helpers.dither_gauge")

-- Dithered used-space gauge (20x11) in place of the drive glyph; the label stays free space.
-- Measure the Data volume: "/" is the sealed system volume, which reads ~12% on a full disk.
local gauge = dither_gauge({ name = "widgets.disk", w = 20, h = 11, canvas = { height = 26, pad_left = 6, nudge = 1 } })
local first_image, gauge_width = gauge(0, false, false)

local disk = sbar.add("item", "widgets.disk", {
  position = "right",
  icon = { drawing = false },
  label = {
    string = "--",
    font = { family = settings.font.numbers, size = 10.0 },
    padding_left = gauge_width + settings.group_paddings,
    padding_right = settings.group_paddings + settings.inner_padding,
  },
  background = {
    color = colors.bg1,
    border_width = 0,
    border_color = colors.bg2,
    image = { string = first_image, drawing = true, scale = 0.5, corner_radius = 0 },
  },
  update_freq = 300,
  updates = true,
})

local function update()
  sbar.exec("df -H /System/Volumes/Data | awk 'NR==2 {print $4\"|\"$5}'", function(result)
    if not result then return end
    local free, pct = result:match("([^|]+)|([^|%s]+)")
    if not free then return end
    free = (free:gsub("%s+", ""))
    local pct_clean = (pct or "0"):gsub("%%", "")
    local used = tonumber(pct_clean) or 0
    -- Warn below 40GB free, read from the same SI string the label shows ("90G", "1.2T").
    local amount, unit = free:match("^([%d.]+)(%a)")
    local free_gb = (tonumber(amount) or 0) * (({ K = 1e-6, M = 1e-3, G = 1, T = 1e3 })[unit] or 0)
    disk:set({
      label = { string = free },
      background = { image = { string = gauge(used / 100, free_gb < 40, false) } },
    })
  end)
end

disk:subscribe("routine", update)
disk:subscribe("system_woke", update)
disk:subscribe("mouse.clicked", function() sbar.exec("open /") end)

update()

sbar.add("item", "widgets.disk.padding", {
  position = "right",
  width = settings.group_paddings,
})
