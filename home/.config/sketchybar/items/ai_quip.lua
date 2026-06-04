local colors = require("colors")
local settings = require("settings")

local quip = sbar.add("item", "ai_quip", {
  position = "left",
  icon = {
    string = "⏣",
    color = colors.amber,
    padding_left = 10,
    padding_right = 8,
    font = { family = settings.font.text, style = settings.font.style_map["Bold"], size = 15.0 },
  },
  label = {
    string = "thinking…",
    color = colors.white,
    max_chars = 70,
    font = { family = settings.font.text, style = settings.font.style_map["Semibold"], size = 12.0 },
    padding_right = 10,
  },
  background = {
    color = colors.with_alpha(colors.amber, 0.10),
    border_color = colors.with_alpha(colors.amber, 0.30),
    border_width = 0,
    corner_radius = 10,
    height = 26,
  },
  update_freq = 1800,
  updates = true,
  scroll_texts = true,
})

local function refresh()
  sbar.exec("$CONFIG_DIR/helpers/ai_quip.sh", function(result)
    if result and #result > 0 then
      quip:set({ label = { string = result } })
    end
  end)
end

quip:subscribe("routine", refresh)
quip:subscribe("forced", refresh)

quip:subscribe("mouse.clicked", function()
  quip:set({ label = { string = "thinking…" } })
  refresh()
end)

refresh()
