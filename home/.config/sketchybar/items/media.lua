local icons = require("icons")
local colors = require("colors")

local ART_PATH = "/tmp/sketchybar_media_art.jpg"

local media = sbar.add("item", "media", {
  position = "left",
  background = {
    image = {
      string = ART_PATH,
      scale = 0.025,
      corner_radius = 4,
      drawing = false,
    },
    color = colors.transparent,
  },
  icon = {
    string = "􀑪",
    color = colors.white,
    font = { size = 14 },
    padding_left = 4,
    padding_right = 4,
  },
  label = {
    string = "",
    max_chars = 45,
    color = colors.white,
    padding_left = 22,
  },
  drawing = false,
  update_freq = 3,
  padding_left = 6,
  padding_right = 6,
  popup = { align = "center", horizontal = true },
})

local function popup_btn(glyph, cmd)
  sbar.add("item", {
    position = "popup." .. media.name,
    icon = { string = glyph },
    label = { drawing = false },
    click_script = cmd,
  })
end

local function player_cmd(action)
  -- action: previous | playpause | next
  local spotify_map = { previous = "previous track", playpause = "playpause", next_ = "next track" }
  local music_map = { previous = "previous track", playpause = "playpause", next_ = "next track" }
  local a = action == "next" and "next_" or action
  return string.format([[
    osascript -e '
      if application "Spotify" is running then
        tell application "Spotify" to %s
      else if application "Music" is running then
        tell application "Music" to %s
      end if'
  ]], spotify_map[a], music_map[a])
end

popup_btn(icons.media.back, player_cmd("previous"))
popup_btn(icons.media.play_pause, player_cmd("playpause"))
popup_btn(icons.media.forward, player_cmd("next"))

local function trim(s) return (s or ""):gsub("^%s*(.-)%s*$", "%1") end

local function fetch_art(url, cb)
  if not url or url == "" or url == "missing value" then cb(false); return end
  -- Music app returns a raw data; Spotify returns a URL.
  if url:match("^https?://") then
    sbar.exec(
      string.format("curl -sL -o %s.tmp %q && [ -s %s.tmp ] && mv %s.tmp %s && echo ok",
        ART_PATH, url, ART_PATH, ART_PATH, ART_PATH),
      function(r) cb(trim(r) == "ok") end
    )
  else
    cb(false)
  end
end

local function render(title, artist, playing, source, art_url)
  if not title or title == "" then
    media:set({ drawing = false })
    return
  end
  local label = title
  if artist and artist ~= "" and artist ~= "missing value" then
    label = artist .. " — " .. title
  end
  local icon_color = playing and 0xff1db954 or colors.white
  if source == "music" then icon_color = playing and 0xfffc3c44 or colors.white end

  media:set({
    drawing = true,
    icon = { string = playing and "􀊄" or "􀊆", color = icon_color },
    label = { string = label },
  })

  fetch_art(art_url, function(has_art)
    media:set({
      background = { image = { drawing = has_art } },
      icon = { drawing = not has_art },
    })
  end)
end

local function update_media()
  local script = [[
    osascript -e '
      if application "Spotify" is running then
        tell application "Spotify"
          if player state is not stopped then
            set t to name of current track
            set a to artist of current track
            set s to player state as string
            set u to artwork url of current track
            return "spotify|||" & t & "|||" & a & "|||" & s & "|||" & u
          end if
        end tell
      end if
      if application "Music" is running then
        tell application "Music"
          if player state is not stopped then
            set t to name of current track
            set a to artist of current track
            set s to player state as string
            return "music|||" & t & "|||" & a & "|||" & s & "|||"
          end if
        end tell
      end if
      return ""'
  ]]
  sbar.exec(script, function(result)
    result = trim(result or "")
    if result == "" then
      media:set({ drawing = false })
      return
    end
    local source, title, artist, state, url = result:match("^(.-)|||(.-)|||(.-)|||(.-)|||(.*)$")
    if not source then
      media:set({ drawing = false })
      return
    end
    render(trim(title), trim(artist), trim(state) == "playing", source, trim(url))
  end)
end

media:subscribe({ "routine", "forced", "system_woke", "media_change" }, update_media)

media:subscribe("mouse.clicked", function()
  media:set({ popup = { drawing = "toggle" } })
end)

media:subscribe("mouse.exited.global", function()
  media:set({ popup = { drawing = false } })
end)

update_media()
