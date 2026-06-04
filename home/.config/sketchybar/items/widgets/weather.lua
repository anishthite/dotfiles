local colors = require("colors")
local settings = require("settings")

local function hm(s)
  return (s or ""):match("^(%d%d:%d%d)")
end

local function to_min(s)
  local h, m = (s or ""):match("^(%d%d):(%d%d)")
  if not h then return nil end
  return tonumber(h) * 60 + tonumber(m)
end

local sun = sbar.add("item", "widgets.weather.sun", {
  position = "right",
  icon = {
    string = "􀆭",
    font = { style = settings.font.style_map["Regular"], size = 13.0 },
    padding_left = settings.group_paddings,
    padding_right = settings.paddings,
    color = colors.yellow,
  },
  label = {
    string = "--:--",
    font = { family = settings.font.numbers, size = 10.0 },
    padding_right = settings.paddings,
  },
})

local weather = sbar.add("item", "widgets.weather", {
  position = "right",
  icon = {
    string = "􀇕",
    font = { style = settings.font.style_map["Regular"], size = 13.0 },
    padding_left = settings.group_paddings,
    padding_right = settings.paddings,
    color = colors.yellow,
  },
  label = {
    string = "--°",
    font = { family = settings.font.numbers, size = 10.0 },
    padding_right = settings.paddings,
  },
  update_freq = 600,
})

local function update_weather()
  sbar.exec([[curl -s 'wttr.in/?format=%t|%S|%s&u']], function(out)
    if not out or out == "" then return end
    out = out:gsub("%s+$", "")
    local temp, sr, ss = out:match("([^|]*)|([^|]*)|([^|]*)")
    if temp then
      temp = temp:gsub("^%+", "")
      weather:set({ label = { string = temp } })
    end

    sbar.exec("date +%H:%M", function(now_str)
      local now = to_min(now_str:gsub("%s+$", ""))
      local sr_m, ss_m = to_min(sr), to_min(ss)
      local next_label, next_icon, next_color = hm(sr), "􀆭", colors.yellow
      if now and sr_m and ss_m then
        if now >= sr_m and now < ss_m then
          next_label, next_icon, next_color = hm(ss), "􀆹", colors.orange
        else
          next_label, next_icon, next_color = hm(sr), "􀆭", colors.yellow
        end
      end
      sun:set({
        icon = { string = next_icon, color = next_color },
        label = { string = next_label or "--:--" },
      })
    end)
  end)
end

weather:subscribe({ "routine", "forced", "system_woke" }, update_weather)

sbar.add("bracket", "widgets.weather.bracket", { weather.name, sun.name }, {
  background = {
    color = colors.bg1,
    border_width = 0,
    border_color = colors.bg2,
  }
})

sbar.add("item", "widgets.weather.padding", {
  position = "right",
  width = settings.group_paddings,
})

update_weather()
