local palette = require("colors").navy_rust

require("items.front_app")
sbar.add("item", "widgets.separator.context", {
  position = "left", width = 16,
  icon = { drawing = false }, label = { string = "│", color = palette.navy, align = "center" },
})
require("items.widgets.weather")
require("items.media")

-- Right items fill inward: date/time, network, then system telemetry.
require("items.calendar")
sbar.add("item", "widgets.separator.clock", {
  position = "right", width = 16,
  icon = { drawing = false }, label = { string = "│", color = palette.navy, align = "center" },
})
require("items.network")
sbar.add("item", "widgets.separator.system", {
  position = "right", width = 16,
  icon = { drawing = false }, label = { string = "│", color = palette.navy, align = "center" },
})
require("items.widgets")
