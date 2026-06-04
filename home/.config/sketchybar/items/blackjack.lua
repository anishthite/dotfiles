local colors = require("colors")
local settings = require("settings")

local BLACKJACK_ENGINE = os.getenv("HOME") .. "/.config/sketchybar/helpers/blackjack_engine.sh"

-- SF Symbol Unicode characters (requires SF Pro font)
local casino_icons = {
  spade = "􀊔",       -- suit.spade.fill
  club = "􀊘",        -- suit.club.fill
  heart = "􀊖",       -- suit.heart.fill
  diamond = "􀊒",     -- suit.diamond.fill
  hand_raised = "􀉼", -- hand.raised.fill
  plus_circle = "􀁍", -- plus.circle.fill
  arrow_ccw = "􀅉",   -- arrow.counterclockwise
  play = "􀊄",        -- play.fill (for Deal)
}

-- ============================================================================
-- BLACKJACK - Premium Casino Widget
-- Aesthetic: Vegas Noir - Gold accents, emerald felt, luxury typography
-- ============================================================================

-- Spacing item before blackjack
sbar.add("item", { position = "right", width = settings.group_paddings })

-- Main blackjack display item
local blackjack = sbar.add("item", "blackjack", {
  position = "right",
  icon = {
    string = casino_icons.spade,
    font = {
      family = "SF Pro",
      style = "Bold",
      size = 13.0,
    },
    color = colors.casino.gold,
    padding_left = 10,
    padding_right = 4,
  },
  label = {
    string = "$1000",
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
      size = 12.0,
    },
    color = colors.casino.gold,
    padding_right = 10,
  },
  background = {
    color = colors.casino.felt_dark,
    corner_radius = 8,
    height = 26,
    border_width = 1,
    border_color = colors.casino.felt,
  },
  padding_left = 2,
  padding_right = 2,
  popup = {
    align = "center",
    horizontal = false,
    background = {
      color = 0xf0121212,
      corner_radius = 12,
      border_width = 2,
      border_color = colors.casino.gold_dark,
      shadow = { drawing = true },
    },
    blur_radius = 30,
  },
})

-- Decorative bracket around main item
sbar.add("bracket", "blackjack.bracket", { blackjack.name }, {
  background = {
    color = colors.transparent,
    corner_radius = 10,
    height = 28,
    border_width = 1,
    border_color = colors.casino.gold_dark,
  },
})

-- Spacing after blackjack
sbar.add("item", { position = "right", width = settings.group_paddings })

-- ============================================================================
-- POPUP MENU ITEMS
-- ============================================================================

-- Title/Status display
local status_display = sbar.add("item", {
  position = "popup." .. blackjack.name,
  icon = {
    string = casino_icons.club,
    font = { family = "SF Pro", style = "Bold", size = 11.0 },
    color = colors.casino.card_white,
    padding_left = 12,
  },
  label = {
    string = "BLACKJACK",
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Heavy"],
      size = 11.0,
    },
    color = colors.casino.card_white,
    padding_right = 12,
  },
  background = {
    color = colors.casino.felt_dark,
    corner_radius = 8,
    height = 28,
    border_width = 1,
    border_color = colors.casino.felt,
  },
  padding_left = 6,
  padding_right = 6,
  padding_top = 8,
  padding_bottom = 4,
})

-- Separator
sbar.add("item", {
  position = "popup." .. blackjack.name,
  icon = { drawing = false },
  label = { drawing = false },
  background = {
    color = colors.with_alpha(colors.casino.gold, 0.3),
    height = 1,
  },
  width = 120,
  padding_top = 4,
  padding_bottom = 4,
})

-- Deal button - Primary action (Gold)
sbar.add("item", {
  position = "popup." .. blackjack.name,
  icon = {
    string = casino_icons.play,
    font = { family = "SF Pro", style = "Bold", size = 12.0 },
    color = colors.black,
    padding_left = 10,
  },
  label = {
    string = "Deal $10",
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Bold"],
      size = 11.0,
    },
    color = colors.black,
    padding_right = 10,
    width = 60,
  },
  background = {
    color = colors.casino.gold,
    corner_radius = 6,
    height = 26,
  },
  padding_left = 6,
  padding_right = 6,
  padding_top = 2,
  padding_bottom = 2,
  click_script = "bash " .. BLACKJACK_ENGINE .. " new_game 10",
})

-- Hit button - Green felt style
sbar.add("item", {
  position = "popup." .. blackjack.name,
  icon = {
    string = casino_icons.plus_circle,
    font = { family = "SF Pro", style = "Bold", size = 12.0 },
    color = colors.casino.card_white,
    padding_left = 10,
  },
  label = {
    string = "Hit",
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Semibold"],
      size = 11.0,
    },
    color = colors.casino.card_white,
    padding_right = 10,
    width = 60,
  },
  background = {
    color = colors.casino.felt,
    corner_radius = 6,
    height = 26,
    border_width = 1,
    border_color = colors.casino.felt_dark,
  },
  padding_left = 6,
  padding_right = 6,
  padding_top = 2,
  padding_bottom = 2,
  click_script = "bash " .. BLACKJACK_ENGINE .. " hit",
})

-- Stand button - Dark elegant
sbar.add("item", {
  position = "popup." .. blackjack.name,
  icon = {
    string = casino_icons.hand_raised,
    font = { family = "SF Pro", style = "Bold", size = 12.0 },
    color = colors.casino.gold,
    padding_left = 10,
  },
  label = {
    string = "Stand",
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Semibold"],
      size = 11.0,
    },
    color = colors.casino.gold,
    padding_right = 10,
    width = 60,
  },
  background = {
    color = colors.casino.chip_black,
    corner_radius = 6,
    height = 26,
    border_width = 1,
    border_color = colors.casino.gold_dark,
  },
  padding_left = 6,
  padding_right = 6,
  padding_top = 2,
  padding_bottom = 2,
  click_script = "bash " .. BLACKJACK_ENGINE .. " stand",
})

-- Separator before reset
sbar.add("item", {
  position = "popup." .. blackjack.name,
  icon = { drawing = false },
  label = { drawing = false },
  background = {
    color = colors.with_alpha(colors.grey, 0.2),
    height = 1,
  },
  width = 120,
  padding_top = 4,
  padding_bottom = 4,
})

-- Reset/New Game button - Subtle
sbar.add("item", {
  position = "popup." .. blackjack.name,
  icon = {
    string = casino_icons.arrow_ccw,
    font = { family = "SF Pro", style = "Regular", size = 10.0 },
    color = colors.grey,
    padding_left = 10,
  },
  label = {
    string = "Reset",
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Regular"],
      size = 10.0,
    },
    color = colors.grey,
    padding_right = 10,
    width = 60,
  },
  background = {
    color = colors.transparent,
    corner_radius = 6,
    height = 22,
  },
  padding_left = 6,
  padding_right = 6,
  padding_top = 2,
  padding_bottom = 8,
  click_script = "bash " .. BLACKJACK_ENGINE .. " reset",
})

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

-- Toggle popup on click
blackjack:subscribe("mouse.clicked", function(env)
  blackjack:set({ popup = { drawing = "toggle" } })
end)

-- Close popup when clicking outside
blackjack:subscribe("mouse.exited.global", function(env)
  blackjack:set({ popup = { drawing = false } })
end)

-- Update balance display
blackjack:subscribe({ "forced", "routine", "system_woke" }, function(env)
  local balance_cmd = io.popen("bash " .. BLACKJACK_ENGINE .. " get_balance 2>/dev/null")
  if balance_cmd then
    local balance_json = balance_cmd:read("*a")
    balance_cmd:close()

    local balance = balance_json:match('"balance"%s*:%s*(%d+)')

    if balance then
      local bal_num = tonumber(balance)
      local color = colors.casino.gold

      -- Color coding: red if losing, brighter gold if winning
      if bal_num < 1000 then
        color = colors.casino.chip_red
      elseif bal_num > 1000 then
        color = colors.casino.gold
      end

      blackjack:set({
        label = {
          string = "$" .. balance,
          color = color,
        },
        icon = { color = color },
      })
    end
  end
end)

-- Hover effect on main item
blackjack:subscribe("mouse.entered", function(env)
  blackjack:set({
    background = {
      color = colors.casino.felt,
      border_color = colors.casino.gold,
    },
  })
end)

blackjack:subscribe("mouse.exited", function(env)
  blackjack:set({
    background = {
      color = colors.casino.felt_dark,
      border_color = colors.casino.felt,
    },
  })
end)
