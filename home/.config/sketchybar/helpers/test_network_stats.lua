-- Run from ~/.config/sketchybar: lua helpers/test_network_stats.lua
local stats = require("helpers.network_stats")
assert(stats.sample("") == nil)
assert(stats.sample("garbage") == nil)
local first = stats.sample("100 en0 1000 2000\n")
assert(first.interface == "en0" and first.down == nil)
local next = stats.sample("102 en0 5000 3000", first)
assert(next.down == 2000 and next.up == 500)
assert(stats.sample("102 en0 5000 3000", next).down == nil)
assert(stats.sample("104 en1 9000 9000", next).down == nil)
assert(stats.sample("104 en0 1 1", next).down == nil)
assert(stats.sample("200 en0 9000 9000", next).down == nil)
assert(stats.sample("104 en0 5000 3000", next).down == 0)
assert(stats.format(nil) == "--")
assert(stats.format(0) == "0B")
assert(stats.format(999) == "999B")
assert(stats.format(1000) == "1.0K")
assert(stats.format(999999) == "1.0M")
assert(stats.format(12500000) == "12M")
assert(stats.format(2000000000) == "2.0G")
-- Exercise the actual widget callbacks without a running SketchyBar instance.
local items, sample, pings = {}, "100 en0 1000 2000", 0
sbar = {
  add = function(_, name, config)
    local item = { name = name, callbacks = {}, popup = "off", config = config }
    function item:subscribe(events, callback)
      for _, event in ipairs(type(events) == "table" and events or { events }) do self.callbacks[event] = callback end
    end
    function item:set(value)
      if value.label then self.label = value.label.string end
      if value.popup then self.popup = value.popup.drawing and "on" or "off" end
    end
    function item:query() return { popup = { drawing = self.popup } } end
    items[name] = item
    return item
  end,
  exec = function(command, callback)
    if command == stats.command then callback(sample)
    elseif command:find("/sbin/ping", 1, true) then pings = pings + 1; callback("64 bytes: time=7.2 ms") end
  end,
}
dofile("items/network.lua")
local network, upload, latency = items["widgets.network"], items["widgets.network.upload"], items["widgets.network.latency"]
assert(network.config.position == "right" and not network.config.background.drawing)
assert(latency.config.position == "popup.widgets.network" and pings == 0)
sample = "102 en0 5000 3000"
network.callbacks.routine()
assert(network.label == "2.0K/s" and upload.label == "500B/s")
network.callbacks["mouse.clicked"]({ BUTTON = "left" })
assert(network.popup == "on" and latency.label == "7ms" and pings == 1)
network.callbacks["mouse.clicked"]({ BUTTON = "left" })
assert(network.popup == "off" and pings == 1)
sample = ""
network.callbacks.routine()
assert(network.label == "OFF" and upload.label == "--/s")
print("network stats and widget: OK")
