-- NERV-OS palette
return {
  black   = 0xff05040a,  -- void
  white   = 0xffe0d8cc,  -- warm off-white text
  red     = 0xffc80010,  -- r400 alert
  green   = 0xff50ff10,  -- g300 terminal green
  blue    = 0xff0cc0b8,  -- c400 NERV cyan (data)
  yellow  = 0xfff4b000,  -- y300 MAGI yellow
  orange  = 0xfff06800,  -- o400 signal orange
  magenta = 0xff9570c7,  -- p400 eva purple
  grey    = 0xff887468,  -- n400 warm neutral
  amber   = 0xfff59b2d,  -- a400 warm amber
  transparent = 0x00000000,

  bar = {
    bg     = 0xee05040a,  -- void w/ slight translucency
    border = 0x662f1f2f,
  },
  popup = {
    bg     = 0xee15111a,
    border = 0xff3e3648,
  },
  bg1 = 0xff15111a,  -- deep surface
  bg2 = 0xff241e2a,  -- raised surface / border

  -- Casino theme colors
  casino = {
    gold = 0xffd4af37,
    gold_dark = 0xffb8960c,
    felt = 0xff1a5c3a,
    felt_dark = 0xff0d3d24,
    chip_red = 0xffc41e3a,
    chip_black = 0xff1a1a1a,
    card_white = 0xfff5f5f5,
  },

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
