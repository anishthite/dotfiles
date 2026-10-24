local settings = require("settings")
local dither_widget = require("helpers.dither_widget")

-- 48 samples at 5s: the last 4min. Rust from 85%, where the old graph turned red.
local mem, update = dither_widget("widgets.memory", { cols = 48, rows = 18, height = 26, pad_left = 6, pad_right = 6, warm_at = 0.85, update_freq = 5 })

local function update_memory()
  local cmd = [[memory_pressure | awk '/System-wide memory free percentage/ {gsub("%","",$5); printf "%.0f", 100-$5}']]
  sbar.exec(cmd, function(usage)
    local used = tonumber(usage) or 0
    update(used / 100.0, string.format("%d%%", used))
  end)
end

mem:subscribe({ "routine", "forced", "system_woke" }, update_memory)
update_memory()

sbar.add("item", "widgets.memory.padding", {
  position = "right",
  width = settings.group_paddings,
})
