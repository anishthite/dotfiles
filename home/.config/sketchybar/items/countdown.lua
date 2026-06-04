local colors = require("colors")
local settings = require("settings")

local function days_until_end_of_month()
  local now = os.time()
  local date = os.date("*t", now)
  local next_month = date.month + 1
  local next_year = date.year
  if next_month > 12 then next_month = 1; next_year = next_year + 1 end
  local end_of_month = os.time({ year = next_year, month = next_month, day = 0, hour = 23, min = 59, sec = 59 })
  return math.ceil(os.difftime(end_of_month, now) / 86400)
end

local function days_until_target()
  local now = os.time()
  local target = os.time({ year = 2026, month = 8, day = 25, hour = 0, min = 0, sec = 0 })
  local diff = os.difftime(target, now)
  if diff < 0 then return 0 end
  return math.ceil(diff / 86400)
end

local function label_text()
  return days_until_target() .. "d · " .. days_until_end_of_month() .. "d"
end

local countdown = sbar.add("item", "countdown", {
  position = "right",
  icon = {
    string = "􀉉",
    font = { family = "SF Pro", style = "Bold", size = 13.0 },
    color = colors.magenta,
    padding_left = settings.group_paddings + settings.inner_padding,
    padding_right = settings.paddings + settings.inner_padding,
  },
  label = {
    string = label_text(),
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
      size = 13.0,
    },
    color = colors.white,
    padding_right = settings.group_paddings + settings.inner_padding,
  },
  background = {
    color = colors.bg1,
    corner_radius = 8,
    border_width = 0,
    height = 26,
  },
  padding_left = settings.paddings,
  padding_right = settings.paddings,
})

countdown:subscribe({ "forced", "routine", "system_woke" }, function()
  countdown:set({ label = { string = label_text() } })
end)
