local colors = require("colors")

local HOME = os.getenv("HOME")
local SPRITE_DIR = HOME .. "/.config/sketchybar/helpers/ghost"
local STATE_FILE = SPRITE_DIR .. "/state.txt"

-- DEBUG: when true, ghost stays put, click = +20, right-click = -20, shows x.
local STATIC_MODE = false
local STATIC_X = 0

-- Calibrated notch bounds
local BOUNDS = {
  normal  = { min = 0, max = 65,  notch_home = 88 },
  minimal = { min = 0, max = 150, notch_home = 175 },
}

-- Need decay rates (seconds until need reaches "critical")
local HUNGER_CRIT  = 3 * 3600    -- 3h since fed = hungry
local HUNGER_STARV = 8 * 3600    -- 8h = starving
local HAPPY_LOW    = 2 * 3600
local HAPPY_SAD    = 6 * 3600
local COFFEE_MAX   = 4           -- too much coffee in a day = jittery

-- Thought bubble symbols
local BUBBLES = {
  hungry   = "!",
  starving = "✗",
  sad      = "♡",
  play     = "?",
  vibe     = "♪",
  petted   = "♥",
  fed      = "◉",
  sleepy   = "z",
  coffee   = "☕",
  fine     = "~",
}

local function now() return os.time() end
local function today_key() return os.date("%Y-%m-%d") end

-- persistent state (simple key=value file)
local function load_state()
  local s = {
    born = now(),
    last_fed = now(),
    last_petted = now(),
    last_played = now(),
    coffee_day = today_key(),
    coffee_count = 0,
    interactions = 0,
  }
  local f = io.open(STATE_FILE, "r")
  if f then
    for line in f:lines() do
      local k, v = line:match("^([%w_]+)=(.*)$")
      if k and v then
        s[k] = tonumber(v) or v
      end
    end
    f:close()
  end
  if s.coffee_day ~= today_key() then
    s.coffee_day = today_key()
    s.coffee_count = 0
  end
  return s
end

local function save_state(s)
  local f = io.open(STATE_FILE, "w")
  if not f then return end
  for k, v in pairs(s) do
    f:write(k .. "=" .. tostring(v) .. "\n")
  end
  f:close()
end

local stats = load_state()

local runtime = {
  x = STATIC_MODE and STATIC_X or 10,
  dx = 6,
  frame = 0,
  bob = 0,
  tick = 0,
  hiding_until = 0,
  awake_until = 0,
  mood = "idle",
  mood_until = 0,
  bubble = nil,
  bubble_until = 0,
  cpu = 0,
  playing = false,
  minimal = false,
}

local ghost = sbar.add("item", "ghost", {
  position = "right",
  background = {
    image = { string = SPRITE_DIR .. "/idle_0.png", scale = 0.4, drawing = true },
    color = colors.transparent,
    drawing = true,
    height = 28,
  },
  icon = { drawing = false },
  label = { drawing = false },
  width = 20,
  padding_left = 0,
  padding_right = 0,
  updates = true,
  update_freq = 1,
  popup = { align = "center", y_offset = 2 },
})

local ghost_bubble = sbar.add("item", "ghost.bubble", {
  position = "popup." .. ghost.name,
  background = {
    color = colors.with_alpha(colors.bg1, 0.95),
    corner_radius = 6,
    border_width = 0,
    height = 20,
  },
  icon = { drawing = false },
  label = {
    string = "",
    font = { family = "SF Pro", style = "Bold", size = 11.0 },
    color = colors.amber or 0xfff9e2af,
    padding_left = 8,
    padding_right = 8,
  },
})

local function time_thought()
  local h = tonumber(os.date("%H"))
  local m = tonumber(os.date("%M"))
  if h >= 0 and h < 6 then return "zzz..."
  elseif h == 6 then return "just waking up"
  elseif h == 7 then return "good morning ☀"
  elseif h == 8 then return "ready for the day"
  elseif h >= 9 and h < 12 then return "morning focus"
  elseif h == 12 then return m < 30 and "almost lunch" or "lunch time?"
  elseif h == 13 then return "post-lunch"
  elseif h == 14 then return "deep work hours"
  elseif h == 15 then return "afternoon grind"
  elseif h == 16 then return "coffee time?"
  elseif h == 17 then return "almost done"
  elseif h == 18 then return "winding down"
  elseif h == 19 then return "evening vibes"
  elseif h == 20 then return "cozy time"
  elseif h == 21 then return "chill hours"
  elseif h == 22 then return "getting late"
  elseif h == 23 then return "should wrap up"
  else return "up late..." end
end

local function hover_thought()
  local parts = {}
  local hunger = now() - stats.last_fed
  local happy  = now() - stats.last_petted
  if hunger > HUNGER_STARV then table.insert(parts, "i'm starving!")
  elseif hunger > HUNGER_CRIT then table.insert(parts, "kinda hungry") end
  if happy > HAPPY_SAD then table.insert(parts, "feeling lonely")
  elseif happy > HAPPY_LOW then table.insert(parts, "wanna play?") end
  if runtime.playing then table.insert(parts, "good tunes ♪") end
  if runtime.cpu > 80 then table.insert(parts, "cpu on fire") end
  if stats.coffee_count > COFFEE_MAX then table.insert(parts, "jittery...") end
  if #parts == 0 then table.insert(parts, time_thought()) end
  if math.random() < 0.3 then
    local days = math.floor((now() - (stats.born or now())) / 86400)
    if days >= 1 then table.insert(parts, string.format("%dd old", days)) end
  end
  return parts[math.random(#parts)]
end

local function bounds() return runtime.minimal and BOUNDS.minimal or BOUNDS.normal end
local function set_mood(m, s) runtime.mood = m; runtime.mood_until = now() + (s or 10) end
local function set_bubble(key, dur)
  runtime.bubble = BUBBLES[key] or key
  runtime.bubble_until = now() + (dur or 4)
end

local function need_level()
  local h_hunger = now() - stats.last_fed
  local h_happy  = now() - stats.last_petted
  if h_hunger > HUNGER_STARV then return "starving" end
  if h_hunger > HUNGER_CRIT  then return "hungry" end
  if h_happy  > HAPPY_SAD    then return "sad" end
  if h_happy  > HAPPY_LOW    then return "bored" end
  return "fine"
end

local function compute_mood()
  if now() < runtime.mood_until then return end

  local hour = tonumber(os.date("%H"))
  -- sleep window: ~12:30am–7am
  local nighttime = hour >= 0 and hour < 7 or hour >= 24
  -- late-night drowsy period before full sleep
  local drowsy = hour == 23 or hour == 0
  local need = need_level()

  if need == "starving" then runtime.mood = "panic"
  elseif need == "hungry" then runtime.mood = "lonely"
  elseif need == "sad" then runtime.mood = "lonely"
  elseif nighttime then runtime.mood = "sleepy"
  elseif drowsy and math.random() < 0.6 then runtime.mood = "sleepy"
  elseif stats.coffee_count > COFFEE_MAX then runtime.mood = "caffeinated"
  elseif runtime.cpu > 80 then runtime.mood = "panic"
  elseif runtime.playing then runtime.mood = "vibe"
  elseif need == "bored" then runtime.mood = "idle"
  else runtime.mood = "idle" end
end

local function maybe_thought()
  if now() < runtime.bubble_until then return end
  if math.random() > 0.10 then return end  -- 10% per tick
  local need = need_level()
  local roll = math.random()
  if need == "starving" then set_bubble("starving", 6)
  elseif need == "hungry" then set_bubble("hungry", 5)
  elseif need == "sad" and roll < 0.8 then set_bubble("sad", 5)
  elseif runtime.mood == "sleepy" and roll < 0.5 then set_bubble("sleepy", 4)
  elseif runtime.mood == "vibe" and roll < 0.6 then set_bubble("vibe", 3)
  elseif runtime.mood == "caffeinated" and roll < 0.6 then set_bubble("coffee", 3)
  elseif roll < 0.3 then set_bubble("play", 3) end
end

local function speed_jitter()
  -- smaller steps since the 45-frame animation fills in between
  local m = runtime.mood
  if m == "happy" then return 4, 0
  elseif m == "caffeinated" then return 8, 2
  elseif m == "sleepy" then return 1, 0
  elseif m == "panic" then return 7, 2
  elseif m == "vibe" then return 5, 0
  elseif m == "lonely" then return 2, 0
  else return 3, 0 end
end

local function apply_visual(pad, y)
  local bubble_on = now() < runtime.bubble_until and runtime.bubble and runtime.bubble ~= ""
  local sprite = string.format("%s/%s_%d.png", SPRITE_DIR, runtime.mood, runtime.frame)
  if bubble_on then
    ghost_bubble:set({ label = { string = runtime.bubble } })
  end
  ghost:set({ popup = { drawing = bubble_on } })
  sbar.animate("sin", 45, function()
    ghost:set({
      padding_right = pad,
      y_offset = y,
      background = { image = { string = sprite, drawing = true } },
    })
  end)
end

local function seconds_until_wake()
  -- If in sleep window (0-7am): hide until 7am. Otherwise: 1h nap.
  local h = tonumber(os.date("%H"))
  if h >= 0 and h < 7 then
    local t = os.date("*t", now())
    t.hour = 7; t.min = 0; t.sec = 0
    local wake = os.time(t)
    if wake <= now() then wake = wake + 86400 end
    return wake - now()
  end
  return 3600
end

local function step()
  runtime.tick = runtime.tick + 1
  runtime.frame = 1 - runtime.frame

  if STATIC_MODE then
    runtime.bubble = "x=" .. runtime.x
    runtime.bubble_until = now() + 9999
    apply_visual(runtime.x, 0)
    return
  end

  compute_mood()
  -- bubbles only show on hover/click, not spontaneously
  -- maybe_thought()

  local b = bounds()
  local awake_override = now() < (runtime.awake_until or 0)

  -- while hiding in notch (but user tap breaks it)
  if now() < runtime.hiding_until and not awake_override then
    apply_visual(b.notch_home, 0)
    return
  end

  -- sleepy: go home and sleep for a long stretch (until 7am or 1h)
  if runtime.mood == "sleepy" and not awake_override then
    runtime.hiding_until = now() + seconds_until_wake()
    apply_visual(b.notch_home, 0)
    return
  end

  -- if awake_override is on but mood is sleepy, ghost wanders sluggishly;
  -- once override expires, next tick it'll go back to hiding

  -- random notch peek
  if runtime.mood ~= "happy" and runtime.mood ~= "caffeinated" and math.random() < 0.04 then
    runtime.hiding_until = now() + math.random(3, 7)
    runtime.x = b.notch_home
    runtime.dx = -math.abs(runtime.dx)
    apply_visual(b.notch_home, 0)
    return
  end

  local speed, jitter = speed_jitter()
  if math.random() < 0.15 then runtime.dx = -runtime.dx end
  local dir = runtime.dx >= 0 and 1 or -1
  runtime.x = runtime.x + dir * speed
  if runtime.x < b.min then runtime.x = b.min; runtime.dx = math.abs(runtime.dx) end
  if runtime.x > b.max then runtime.x = b.max; runtime.dx = -math.abs(runtime.dx) end

  runtime.bob = (runtime.bob == 0) and -2 or 0
  local y = runtime.bob + (jitter > 0 and math.random(-jitter, jitter) or 0)
  local pad = runtime.x + (jitter > 0 and math.random(-jitter, jitter) or 0)
  apply_visual(pad, y)

  if runtime.tick % 10 == 0 then
    sbar.exec([[ps -A -o %cpu | awk 'NR>1{s+=$1} END{printf "%.0f", s/8}']], function(r)
      runtime.cpu = tonumber((r or ""):gsub("%s+", "")) or 0
    end)
    sbar.exec([[osascript -e 'if application "Spotify" is running then tell application "Spotify" to return player state as string' 2>/dev/null]],
      function(r) runtime.playing = (r or ""):match("playing") ~= nil end)
  end

  if runtime.tick % 60 == 0 then save_state(stats) end
end

ghost:subscribe({ "routine", "forced", "system_woke" }, step)

ghost:subscribe("ghost_minimal", function(env)
  runtime.minimal = (env.on == "1" or env.on == "true")
  local b = bounds()
  if runtime.x > b.max then runtime.x = b.max end
  step()
end)

ghost:subscribe("mouse.entered", function()
  runtime.bubble = hover_thought()
  runtime.bubble_until = now() + 6
  step()
end)

ghost:subscribe("mouse.exited", function()
  runtime.bubble_until = 0
  step()
end)

ghost:subscribe("mouse.clicked", function(env)
  if STATIC_MODE then
    if env.BUTTON == "right" then runtime.x = runtime.x - 10
    else runtime.x = runtime.x + 10 end
    if runtime.x < 0 then runtime.x = 0 end
    step()
    return
  end

  runtime.hiding_until = 0
  runtime.awake_until = now() + 90   -- wakes for ~90s before going back to bed
  stats.interactions = (stats.interactions or 0) + 1

  if env.BUTTON == "right" then
    -- feed coffee
    if stats.coffee_day ~= today_key() then
      stats.coffee_day = today_key(); stats.coffee_count = 0
    end
    stats.coffee_count = stats.coffee_count + 1
    stats.last_fed = now()
    if stats.coffee_count > COFFEE_MAX then
      set_mood("caffeinated", 120); set_bubble("coffee", 6)
    else
      set_mood("caffeinated", 60); set_bubble("fed", 5)
    end
  else
    -- pet
    stats.last_petted = now()
    set_mood("happy", 10); set_bubble("petted", 5)
  end
  save_state(stats)
  step()
end)

-- Query commands via custom event (from shell if desired)
sbar.exec("sketchybar --add event ghost_query 2>/dev/null; true", function() end)

math.randomseed(os.time())
step()
