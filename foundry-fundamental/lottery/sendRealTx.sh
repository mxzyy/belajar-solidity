#!/usr/bin/env bash
set -euo pipefail

# =========================
# Config
# =========================

RPC_URL="${RPC_URL:-http://127.0.0.1:8545}"
RAFFLE="0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9"
VRF="0x5FbDB2315678afecb367f032d93F642f64180aa3"

# 3 private key default anvil
PK1="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
PK2="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
PK3="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"

ADDR1=$(cast wallet address --private-key "$PK1")
ADDR2=$(cast wallet address --private-key "$PK2")
ADDR3=$(cast wallet address --private-key "$PK3")

echo "RPC_URL      : $RPC_URL"
echo "Raffle       : $RAFFLE"
echo "VRF Coord    : $VRF"
echo "Player 1 addr: $ADDR1"
echo "Player 2 addr: $ADDR2"
echo "Player 3 addr: $ADDR3"
echo

# =========================
# Fixed entrance fee
# =========================
# Sesuaikan dengan HelperConfig: raffleEntranceFee: 0.01 ether
ENTRANCE_FEE=$(cast --to-wei 0.01 ether)
echo "Using fixed entrance fee: $ENTRANCE_FEE wei (0.01 ether)"
echo

# =========================
# 3 players enterRaffle
# =========================

echo ">>> Player 1 entering raffle..."
cast send "$RAFFLE" "enterRaffle()" \
  --value "$ENTRANCE_FEE" \
  --private-key "$PK1" \
  --rpc-url "$RPC_URL"

echo
echo ">>> Player 2 entering raffle..."
cast send "$RAFFLE" "enterRaffle()" \
  --value "$ENTRANCE_FEE" \
  --private-key "$PK2" \
  --rpc-url "$RPC_URL"

echo
echo ">>> Player 3 entering raffle..."
cast send "$RAFFLE" "enterRaffle()" \
  --value "$ENTRANCE_FEE" \
  --private-key "$PK3" \
  --rpc-url "$RPC_URL"

echo
echo "3 players have entered the raffle."
echo

# =========================
# Time travel (interval)
# =========================

echo "Advancing time to satisfy interval..."

# Kalau lu punya getter lain (misal i_interval()), ganti signature ini
INTERVAL=$(cast call "$RAFFLE" "getInterval()(uint256)" --rpc-url "$RPC_URL")
echo "Interval: $INTERVAL seconds"

cast rpc evm_increaseTime "$((INTERVAL + 1))" --rpc-url "$RPC_URL" > /dev/null
cast rpc evm_mine --rpc-url "$RPC_URL" > /dev/null

echo "Time moved by $((INTERVAL + 1)) seconds."
echo

# =========================
# performUpkeep
# =========================

echo "Calling performUpkeep..."

UPKEEP_TX_HASH=$(
  cast send "$RAFFLE" \
    "performUpkeep(bytes)" 0x \
    --private-key "$PK1" \
    --rpc-url "$RPC_URL" \
  | grep -o '0x[0-9a-fA-F]\{64\}' \
  | tail -n 1
)

echo "performUpkeep tx hash: $UPKEEP_TX_HASH"
echo

# =========================
# Extract requestId from RequestedRaffleWinner event
# =========================

echo "Fetching requestId from RequestedRaffleWinner event..."

EVENT_SIG=$(cast keccak "RequestedRaffleWinner(uint256)")
RECEIPT_JSON=$(cast receipt "$UPKEEP_TX_HASH" --rpc-url "$RPC_URL" --json)

LOWER_RAFFLE=$(echo "$RAFFLE" | tr 'A-Z' 'a-z')
REQ_ID_HEX=$(
  echo "$RECEIPT_JSON" \
  | jq -r ".logs[]
           | select(.address | ascii_downcase == \"$LOWER_RAFFLE\")
           | .topics[1]" \
  | head -n 1
)

echo "requestId (hex) = $REQ_ID_HEX"
if [[ -z "$REQ_ID_HEX" || "$REQ_ID_HEX" == "null" ]]; then
  echo "Failed to find RequestedRaffleWinner event in logs."
  exit 1
fi

echo "requestId (hex): $REQ_ID_HEX"
echo

# =========================
# fulfillRandomWords via VRF mock
# =========================

echo "Calling VRF fulfillRandomWords..."

cast send "$VRF" \
  "fulfillRandomWords(uint256,address)" \
  "$REQ_ID_HEX" "$RAFFLE" \
  --private-key "$PK1" \
  --rpc-url "$RPC_URL"

echo
echo "VRF fulfilled. Checking winner..."
echo

# =========================
# Check recent winner
# =========================

WINNER=$(cast call "$RAFFLE" "getRecentWinner()(address)" --rpc-url "$RPC_URL")
echo "Recent winner: $WINNER"
echo
echo "Done. Raffle simulation with 3 EOAs complete 🎲"
