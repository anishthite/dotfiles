local settings = require("settings")
local colors = require("colors")

-- Equivalent to the --default domain
sbar.default({
  updates = "when_shown",
  icon = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Bold"],
      size = 13.0
    },
    color = colors.white,
    padding_left = settings.group_paddings + settings.inner_padding,
    padding_right = settings.paddings + settings.inner_padding,
    background = { image = { corner_radius = 9 } },
  },
  label = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Semibold"],
      size = 12.0
    },
    color = colors.white,
    padding_left = settings.paddings + settings.inner_padding,
    padding_right = settings.group_paddings + settings.inner_padding,
  },
  background = {
    height = 26,
    corner_radius = 8,
    border_width = 0,
    border_color = colors.transparent,
    image = {
      corner_radius = 8,
      border_color = colors.transparent,
      border_width = 0,
    },
  },
  popup = {
    background = {
      border_width = 2,
      corner_radius = 9,
      border_color = colors.popup.border,
      color = colors.popup.bg,
      shadow = { drawing = true },
    },
    blur_radius = 50,
  },
  padding_left = 0,
  padding_right = 0,
  scroll_texts = true,
})
