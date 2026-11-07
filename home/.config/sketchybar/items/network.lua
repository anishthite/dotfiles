local palette = require("colors").navy_rust
local stats = require("helpers.network_stats")

-- Right-side items are laid out in reverse creation order.
local upload = sbar.add("item", "widgets.network.upload", {
  position = "right",
  icon = { string = "↑", color = palette.blue, padding_left = 2, padding_right = 1 },
  label = { string = "--/s", color = palette.paper, width = 56, align = "right", padding_left = 1, padding_right = 2 },
  background = { drawing = false },
})
local network = sbar.add("item", "widgets.network", {
  position = "right",
  icon = { string = "↓", color = palette.blue, padding_left = 2, padding_right = 1 },
  label = { string = "--/s", color = palette.paper, width = 56, align = "right", padding_left = 1, padding_right = 2 },
  background = { drawing = false },
  update_freq = 2,
  popup = { align = "center" },
})
local latency = sbar.add("item", "widgets.network.latency", {
  position = "popup." .. network.name,
  icon = { string = "Latency", color = palette.blue },
  label = { string = "--ms", color = palette.paper, width = 70, align = "right" },
})

local previous, sampling, pinging
local function update()
  if sampling then return end
  sampling = true
  sbar.exec(stats.command, function(result)
    sampling = false
    local current = stats.sample(result, previous)
    previous = current
    network:set({ label = {
      string = current and stats.format(current.down) .. "/s" or "OFF",
      color = current and palette.paper or palette.orange,
    } })
    upload:set({ label = {
      string = current and stats.format(current.up) .. "/s" or "--/s",
      color = current and palette.paper or palette.orange,
    } })
  end)
end
network:subscribe({ "routine", "forced", "wifi_change" }, update)
network:subscribe("system_woke", function() previous = nil; update() end)

local function show_details(env)
  if env.BUTTON == "right" then
    sbar.exec("open 'x-apple.systempreferences:com.apple.Network-Settings.extension'")
    return
  end
  local opening = network:query().popup.drawing == "off"
  network:set({ popup = { drawing = opening } })
  if not opening or pinging then return end
  pinging = true
  latency:set({ label = { string = "…", color = palette.paper } })
  sbar.exec("/sbin/ping -n -c 1 -W 1000 1.1.1.1 2>/dev/null", function(result)
    pinging = false
    local ms = tonumber((result or ""):match("time[=<]([%d.]+)"))
    latency:set({ label = {
      string = ms and string.format("%.0fms", ms) or "--ms",
      color = ms and ms < 100 and palette.paper or palette.orange,
    } })
  end)
end
for _, item in ipairs({ network, upload }) do
  item:subscribe("mouse.clicked", show_details)
  item:subscribe("mouse.exited.global", function() network:set({ popup = { drawing = false } }) end)
end
update()
