local settings = require("settings")
local dither_widget = require("helpers.dither_widget")

sbar.exec("killall cpu_load >/dev/null; $CONFIG_DIR/helpers/event_providers/cpu_load/bin/cpu_load cpu_update 2.0")

-- 48 samples at 2s: the last ~95s. Rust from 60%, where the old graph turned orange.
local cpu, update = dither_widget("widgets.cpu", { cols = 48, rows = 18, height = 26, pad_left = 6, pad_right = 6, warm_at = 0.6 })

cpu:subscribe("cpu_update", function(env)
  local load = tonumber(env.total_load) or 0
  update(load / 100., env.total_load .. "%")
end)

sbar.add("item", "widgets.cpu.padding", {
  position = "right",
  width = settings.group_paddings,
})
