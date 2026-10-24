-- Require the sketchybar module
sbar = require("sketchybar")

-- Set the bar name, if you are using another bar instance than sketchybar
-- sbar.set_bar_name("bottom_bar")

-- Bundle the entire initial configuration into a single message to sketchybar
sbar.add("event", "ghost_minimal")
sbar.begin_config()
require("bar")
require("default")
require("items")

-- Apply consistent, readable sizes to every widget and popup.
sbar.set("/.*/", { icon = { font = { size = 15.0 } }, label = { font = { size = 14.0 } } })
-- The calendar draws its date as icon text: keep it at label size so date and time share a baseline.
sbar.set("calendar", { icon = { font = { size = 14.0 } } })
sbar.end_config()

-- Run the event loop of the sketchybar module (without this there will be no
-- callback functions executed in the lua module)
sbar.event_loop()
