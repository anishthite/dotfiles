#!/bin/bash

# Blackjack Game Engine
# Handles all game logic, state management, and calculations

BLACKJACK_DIR="${HOME}/.config/sketchybar/cache/blackjack"
STATE_FILE="${BLACKJACK_DIR}/state.json"
BALANCE_FILE="${BLACKJACK_DIR}/balance.json"

# Create cache directory if it doesn't exist
mkdir -p "$BLACKJACK_DIR"

# Initialize state file if it doesn't exist
init_state() {
  if [[ ! -f "$STATE_FILE" ]]; then
    cat > "$STATE_FILE" << 'EOF'
{
  "game_state": "idle",
  "player_hand": [],
  "dealer_hand": [],
  "player_score": 0,
  "dealer_score": 0,
  "current_bet": 0,
  "message": "Ready to play"
}
EOF
  fi

  if [[ ! -f "$BALANCE_FILE" ]]; then
    cat > "$BALANCE_FILE" << 'EOF'
{
  "balance": 1000,
  "total_won": 0,
  "total_lost": 0,
  "games_played": 0
}
EOF
  fi
}

# Deck functions
get_random_card() {
  # Returns a random card value (1-13)
  echo $((RANDOM % 13 + 1))
}

card_value() {
  # Get numeric value of a card
  local card=$1
  if [[ $card -eq 1 ]]; then
    echo "11"  # Ace = 11 initially
  elif [[ $card -gt 10 ]]; then
    echo "10"  # Face cards = 10
  else
    echo "$card"
  fi
}

card_name() {
  # Get name of a card
  local card=$1
  case $card in
    1) echo "A" ;;
    11) echo "J" ;;
    12) echo "Q" ;;
    13) echo "K" ;;
    *) echo "$card" ;;
  esac
}

# Hand calculation
calculate_hand_value() {
  local hand=$1
  local total=0
  local aces=0

  IFS=',' read -ra CARDS <<< "$hand"

  for card in "${CARDS[@]}"; do
    value=$(card_value "$card")
    total=$((total + value))
    if [[ $card -eq 1 ]]; then
      ((aces++))
    fi
  done

  # Adjust for aces if busted
  while [[ $total -gt 21 && $aces -gt 0 ]]; do
    total=$((total - 10))
    ((aces--))
  done

  echo "$total"
}

# Game logic
new_game() {
  local bet=$1
  local balance=$(jq -r '.balance' "$BALANCE_FILE")

  if [[ $bet -gt $balance ]]; then
    echo '{"error": "Insufficient funds"}'
    return
  fi

  # Deal initial cards (2 each)
  local player_card1=$(get_random_card)
  local player_card2=$(get_random_card)
  local dealer_card1=$(get_random_card)
  local dealer_card2=$(get_random_card)

  local player_hand="${player_card1},${player_card2}"
  local dealer_hand="${dealer_card1},${dealer_card2}"

  local player_score=$(calculate_hand_value "$player_hand")
  local dealer_score=$(calculate_hand_value "$dealer_hand")

  # Update balance
  local new_balance=$((balance - bet))
  jq ".balance = $new_balance" "$BALANCE_FILE" > "${BALANCE_FILE}.tmp" && mv "${BALANCE_FILE}.tmp" "$BALANCE_FILE"

  # Save state
  cat > "$STATE_FILE" << EOF
{
  "game_state": "playing",
  "player_hand": "$player_hand",
  "dealer_hand": "$dealer_hand",
  "player_score": $player_score,
  "dealer_score": $dealer_score,
  "current_bet": $bet,
  "message": "Your turn"
}
EOF

  cat "$STATE_FILE"
}

hit() {
  local state=$(cat "$STATE_FILE")
  local player_hand=$(echo "$state" | jq -r '.player_hand')
  local new_card=$(get_random_card)

  player_hand="${player_hand},${new_card}"
  local player_score=$(calculate_hand_value "$player_hand")

  local message="Your turn"
  local game_state="playing"

  if [[ $player_score -gt 21 ]]; then
    game_state="bust"
    message="Bust! Dealer wins."
  fi

  jq ".player_hand = \"$player_hand\" | .player_score = $player_score | .game_state = \"$game_state\" | .message = \"$message\"" "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"

  cat "$STATE_FILE"
}

stand() {
  local state=$(cat "$STATE_FILE")
  local dealer_hand=$(echo "$state" | jq -r '.dealer_hand')
  local dealer_score=$(calculate_hand_value "$dealer_hand")
  local player_score=$(echo "$state" | jq -r '.player_score')
  local current_bet=$(echo "$state" | jq -r '.current_bet')

  # Dealer hits until 17 or higher
  while [[ $dealer_score -lt 17 ]]; do
    local new_card=$(get_random_card)
    dealer_hand="${dealer_hand},${new_card}"
    dealer_score=$(calculate_hand_value "$dealer_hand")
  done

  # Determine winner
  local message=""
  local payout=0

  if [[ $dealer_score -gt 21 ]]; then
    message="Dealer bust! You win!"
    payout=$((current_bet * 2))
  elif [[ $player_score -gt $dealer_score ]]; then
    message="You win!"
    payout=$((current_bet * 2))
  elif [[ $player_score -eq $dealer_score ]]; then
    message="Push! Bet returned."
    payout=$current_bet
  else
    message="Dealer wins."
    payout=0
  fi

  # Update balance and stats
  local current_balance=$(jq -r '.balance' "$BALANCE_FILE")
  local new_balance=$((current_balance + payout))

  jq ".balance = $new_balance | .games_played += 1 | if $payout > $current_bet then .total_won += ($payout - $current_bet) else .total_lost += ($current_bet - $payout) end" "$BALANCE_FILE" > "${BALANCE_FILE}.tmp" && mv "${BALANCE_FILE}.tmp" "$BALANCE_FILE"

  # Update game state
  cat > "$STATE_FILE" << EOF
{
  "game_state": "ended",
  "player_hand": "$(echo "$state" | jq -r '.player_hand')",
  "dealer_hand": "$dealer_hand",
  "player_score": $player_score,
  "dealer_score": $dealer_score,
  "current_bet": 0,
  "message": "$message (You won \$$((payout - current_bet)))",
  "payout": $payout
}
EOF

  cat "$STATE_FILE"
}

get_state() {
  if [[ -f "$STATE_FILE" ]]; then
    cat "$STATE_FILE"
  else
    init_state
    cat "$STATE_FILE"
  fi
}

get_balance() {
  if [[ -f "$BALANCE_FILE" ]]; then
    cat "$BALANCE_FILE"
  else
    init_state
    cat "$BALANCE_FILE"
  fi
}

reset_game() {
  cat > "$STATE_FILE" << 'EOF'
{
  "game_state": "idle",
  "player_hand": [],
  "dealer_hand": [],
  "player_score": 0,
  "dealer_score": 0,
  "current_bet": 0,
  "message": "Ready to play"
}
EOF
  cat "$STATE_FILE"
}

# Main logic
init_state

case "$1" in
  new_game)
    new_game "$2"
    ;;
  hit)
    hit
    ;;
  stand)
    stand
    ;;
  get_state)
    get_state
    ;;
  get_balance)
    get_balance
    ;;
  reset)
    reset_game
    ;;
  *)
    get_state
    ;;
esac
