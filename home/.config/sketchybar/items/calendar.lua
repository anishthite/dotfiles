local settings = require("settings")
local colors = require("colors")

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

local cal = sbar.add("item", {
  icon = {
    color = colors.white,
    padding_left = settings.group_paddings + settings.inner_padding,
    font = {
      style = settings.font.style_map["Semibold"],
      size = 11.0,
    },
  },
  label = {
    color = colors.white,
    padding_right = settings.group_paddings + settings.inner_padding,
    width = 64,
    align = "right",
    font = { family = settings.font.numbers, size = 11.0 },
  },
  position = "right",
  update_freq = 1,
  padding_left = 0,
  padding_right = 0,
  background = {
    color = colors.bg1,
    border_color = colors.bg2,
    border_width = 0
  },
})

local minimal = false
local hidden_patterns = { "/widgets%..*/", "countdown", "media", "ai_quip" }

cal:subscribe("mouse.clicked", function(env)
  if env.BUTTON == "right" then
    sbar.exec("open -a 'Calendar'")
    return
  end
  minimal = not minimal
  for _, pat in ipairs(hidden_patterns) do
    sbar.set(pat, { drawing = not minimal })
  end
  sbar.trigger("ghost_minimal", { on = minimal and "1" or "0" })
end)

-- Double border for calendar using a single item bracket
sbar.add("bracket", { cal.name }, {
  background = {
    color = colors.transparent,
    height = 26,
    border_color = colors.bg2,
    border_width = 0,
  }
})

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

cal:subscribe({ "forced", "routine", "system_woke" }, function(env)
  cal:set({ icon = os.date("%a %d %b"), label = os.date("%H:%M:%S") })
end)
