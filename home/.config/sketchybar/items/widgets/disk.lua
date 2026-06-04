local colors = require("colors")
local settings = require("settings")

local disk = sbar.add("item", "widgets.disk", {
  position = "right",
  icon = {
    string = "􀪰",
    color = colors.blue,
    font = { style = settings.font.style_map["Bold"], size = 13.0 },
    padding_left = settings.group_paddings + settings.inner_padding,
    padding_right = settings.paddings + settings.inner_padding,
  },
  label = {
    string = "--",
    font = { family = settings.font.numbers, size = 10.0 },
    padding_right = settings.group_paddings + settings.inner_padding,
  },
  background = {
    color = colors.bg1,
    border_width = 0,
    border_color = colors.bg2,
  },
  update_freq = 300,
  updates = true,
})

local function update()
  sbar.exec("df -H / | awk 'NR==2 {print $4\"|\"$5}'", function(result)
    if not result then return end
    local free, pct = result:match("([^|]+)|([^|%s]+)")
    if not free then return end
    free = (free:gsub("%s+", ""))
    local pct_clean = (pct or "0"):gsub("%%", "")
    local used = tonumber(pct_clean) or 0
    local color = colors.blue
    if used >= 90 then color = colors.red
    elseif used >= 75 then color = colors.orange
    end
    disk:set({
      label = { string = free },
      icon = { color = color },
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
