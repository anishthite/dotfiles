#!/bin/bash
# Generates a short line via the claude CLI for the status bar.

CACHE_FILE="$HOME/.config/sketchybar/cache/ai_quip.txt"
mkdir -p "$(dirname "$CACHE_FILE")"

FALLBACKS=(
  "octopuses taste with their arms — each sucker is a tongue"
  "if you yell for 8y 7m 6d you produce enough energy to heat coffee"
  "your stomach gets a new lining every 3-4 days"
  "honey never spoils — 3000y old jars are still edible"
  "the shortest war in history lasted 38 minutes"
  "bananas are berries, strawberries are not"
  "a day on venus is longer than its year"
  "wombats poop cubes so it doesn't roll away"
  "sharks existed before trees did"
  "the word 'set' has 430 meanings in the OED"
  "cows have best friends and get stressed when apart"
  "if the sun were the size of a blood cell, the galaxy = the US"
  "every breath you take contains atoms breathed by caesar"
  "your tongue is the strongest muscle relative to size"
  "you are closer in time to cleopatra than she was to pyramids"
  "—"
  "what if déjà vu is just a save point working"
  "the dot on the i is called a tittle"
  "if you pour water in a glass shaped like a duck, it's just duck"
  "nobody has ever been alive and not had a name"
  "the past is just the future that already shipped"
  "you are the oldest you've ever been, and the youngest you'll be"
  "your eyes see upside down. your brain flips it"
  "you can't hum while holding your nose"
  "the average cloud weighs about a million pounds"
  "time is the only thing nobody has enough of, and everyone wastes"
  "every photo of you is already of someone you aren't anymore"
)

PROMPT="Output ONE short line for a desktop status bar. 40-65 chars.
No quotes, no emojis, no preamble — just the line.
Each call, silently pick ONE mode at random:
- fun fact (science, history, nature, language)
- shower thought (surprising angle on the ordinary)
- one-liner joke (dry, unexpected — not a pun, not cringe)
- life tip (practical, non-obvious, useful in under a minute)
- historical 'on this day' moment
- absurd but true statistic
Rules: no programmer jokes. no motivational fluff. no hashtags.
must be true if presented as a fact. if it sounds AI-generated,
discard and pick a different mode."

RESULT=$(/Users/anishthite/.local/bin/claude -p "$PROMPT" --model haiku 2>/dev/null | head -c 90 | tr -d '\n' | sed 's/^["'\'']//;s/["'\'']$//')

if [ -z "$RESULT" ] || [ ${#RESULT} -gt 80 ]; then
  RESULT="${FALLBACKS[$RANDOM % ${#FALLBACKS[@]}]}"
fi

echo -n "$RESULT" > "$CACHE_FILE"
echo -n "$RESULT"
