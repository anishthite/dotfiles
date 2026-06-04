local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

-- Padding item required because of bracket
sbar.add("item", { width = 3 })

local apple = sbar.add("item", {
  icon = {
    font = { size = 14.0 },
    string = icons.apple,
    padding_right = 6,
    padding_left = 6,
  },
  label = { drawing = false },
  background = {
    color = colors.bg2,
    border_color = colors.bg2,
    border_width = 0
  },
  padding_left = 0,
  padding_right = 0,
  click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0"
})

-- Double border for apple using a single item bracket
sbar.add("bracket", { apple.name }, {
  background = {
    color = colors.transparent,
    height = 26,
    border_color = colors.bg2,
  }
})

-- Padding item required because of bracket
sbar.add("item", { width = 5 })
