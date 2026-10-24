local colors = require("colors")
local settings = require("settings")

-- An animated math visual pinned to the left edge of the notch, beside the Spotify status.
-- helpers/art/bin/bar_art renders the frames; it animates only while Spotify or Music
-- is playing and freezes, dimmed, when paused. Click to cycle pieces.
local W, H = 128, 24
local PIECES = {
  { id = "fourier", name = "Fourier series" },
  { id = "zeta", name = "Riemann zeta" },
  { id = "julia", name = "Julia sets" },
  { id = "clifford", name = "Clifford attractor" },
  { id = "harmonograph", name = "Harmonograph" },
  { id = "lissajous", name = "Lissajous table" },
  { id = "taylor", name = "Taylor series" },
}
local PIECE_FILE = os.getenv("HOME") .. "/.config/sketchybar/cache/art_piece"

local function read_piece()
  local f = io.open(PIECE_FILE, "r")
  if not f then return 1 end
  local id = (f:read("*l") or ""):gsub("%s", "")
  f:close()
  for i, piece in ipairs(PIECES) do
    if piece.id == id then return i end
  end
  return 1
end

local current = read_piece()

sbar.exec(string.format(
  "killall bar_art >/dev/null 2>&1; $CONFIG_DIR/helpers/art/bin/bar_art music_art %d %d 10 0x%08x 0x%08x %q",
  W, H, colors.blue, colors.orange, PIECE_FILE
))

local art = sbar.add("item", "music_art", {
  position = "q",
  width = W,
  icon = { drawing = false },
  label = { drawing = false },
  background = {
    color = colors.transparent,
    height = H,
    image = { string = "/tmp/sketchybar_art/music_art_1.png", scale = 0.5, drawing = true },
  },
  padding_left = 10,
  padding_right = 12,
  popup = { align = "center", y_offset = 2 },
})

local caption = sbar.add("item", "music_art.caption", {
  position = "popup." .. art.name,
  icon = { drawing = false },
  label = {
    string = PIECES[current].name,
    font = { family = settings.font.text, style = settings.font.style_map["Bold"], size = 11.0 },
    color = colors.blue,
    padding_left = 8,
    padding_right = 8,
  },
})

local function show_caption(text)
  caption:set({ label = { string = text } })
  art:set({ popup = { drawing = true } })
end

art:subscribe("mouse.clicked", function()
  current = current % #PIECES + 1
  local f = io.open(PIECE_FILE, "w")
  if f then
    f:write(PIECES[current].id .. "\n")
    f:close()
  end
  show_caption(PIECES[current].name)
end)

art:subscribe("mouse.entered", function()
  show_caption(PIECES[current].name .. "  ·  click for next")
end)

art:subscribe("mouse.exited", function()
  art:set({ popup = { drawing = false } })
end)
