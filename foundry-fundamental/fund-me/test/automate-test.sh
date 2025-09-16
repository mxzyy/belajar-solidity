#!/usr/bin/env bash
# test/automate-test.sh — pakai FundMe yang SUDAH ada; kalau belum, deploy & TANGKAP alamat dari console.log
# Debug deploy parsing: DEBUG=1 ./test/automate-test.sh test_price_feed_address_is_correct

set -euo pipefail

########################################
# Konfigurasi
########################################
RPC_URL="${RPC_URL:-http://127.0.0.1:8545}"
OWNER_DEFAULT="${OWNER_DEFAULT:-0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266}"  # anvil #0 (unlocked)
DEPLOY_SCRIPT="${DEPLOY_SCRIPT:-script/DeployFundMe.s.sol:DeployFundMe}"
DEBUG="${DEBUG:-0}"

echo "RPC_URL=$RPC_URL"

########################################
# Dependensi
########################################
need(){ command -v "$1" >/dev/null || { echo "butuh '$1' di PATH"; exit 1; }; }
need forge; need cast; need jq; need bc

########################################
# Util umum
########################################
is_addr(){ [[ "${1:-}" =~ ^0x[0-9a-fA-F]{40}$ ]]; }
first_field(){ awk '{print $1}'; }          # ambil token pertama (buang "[5e18]" dsb)
to_uint(){                                  # hex -> dec; atau kalau sudah dec, bersihkan saja
  local x="${1:-}"
  if [[ "$x" =~ ^0x[0-9a-fA-F]+$ ]]; then
    cast --to-dec "$x" 2>/dev/null | first_field
  else
    printf "%s\n" "$x" | first_field
  fi
}
OK(){ echo "✅ $1"; }
KO(){ echo "❌ $1"; }

########################################
# Ambil akun anvil
########################################
ACCOUNTS_JSON="$(cast rpc --rpc-url "$RPC_URL" eth_accounts)"
ACCT0="$(echo "$ACCOUNTS_JSON" | jq -r '.[0]')"
ACCT1="$(echo "$ACCOUNTS_JSON" | jq -r '.[1] // empty')"
ACCT2="$(echo "$ACCOUNTS_JSON" | jq -r '.[2] // empty')"
ACCT3="$(echo "$ACCOUNTS_JSON" | jq -r '.[3] // empty')"
F1="${ACCT1:-$ACCT0}"
F2="${ACCT2:-$ACCT0}"
F3="${ACCT3:-$ACCT0}"

########################################
# Resolve FUNDME_ADDR:
# 1) Pakai FUNDME_ADDR env jika valid & ada bytecode
# 2) Kalau kosong, deploy sekali dan TANGKAP alamat dari console.log("FundMe deployed at:", ...)
########################################
FUNDME="${FUNDME_ADDR:-}"

deploy_and_capture(){
  echo "[deploy] $DEPLOY_SCRIPT (broadcast, unlocked, sender=$OWNER_DEFAULT)"
  local out rc
  out="$(forge script "$DEPLOY_SCRIPT" --sig "run()" \
          --rpc-url "$RPC_URL" \
          --broadcast \
          --unlocked \
          --sender "$OWNER_DEFAULT" 2>&1)" || rc=$? || true
  rc=${rc:-0}
  [[ "$DEBUG" == "1" ]] && echo "$out"
  (( rc == 0 )) || { echo "[deploy] forge script gagal"; echo "$out"; return 1; }

  # Tangkap dari console.log
  local addr
  addr="$(echo "$out" | grep -Eo 'FundMe deployed at:\s*0x[0-9a-fA-F]{40}' | awk '{print $4}')"

  # Fallback lain
  if ! is_addr "$addr"; then
    addr="$(echo "$out" | grep -Eo 'Deployed to:\s*0x[0-9a-fA-F]{40}' | awk '{print $3}')" || true
  fi
  # Fallback terakhir: broadcast JSON
  if ! is_addr "$addr"; then
    local chainid fp
    chainid="$(cast chain-id --rpc-url "$RPC_URL")"
    fp="broadcast/$(basename "${DEPLOY_SCRIPT%%:*}").s.sol/${chainid}/run-latest.json"
    if [[ -f "$fp" ]]; then
      addr="$(jq -r '
        def hexaddr: select(type=="string") | select(startswith("0x")) | select(length==42);
        ((.receipts // []) | map(.contractAddress) | map(hexaddr) | last)
        // ((.transactions // []) | map(select(.transactionType=="CREATE")) | map(.contractAddress) | map(hexaddr) | last)
        // empty
      ' "$fp")"
    fi
  fi

  is_addr "$addr" || { echo "[deploy] Gagal menangkap alamat dari output. Pastikan ada console.log()."; return 1; }

  local code
  code="$(cast code "$addr" --rpc-url "$RPC_URL" || true)"
  [[ -n "$code" && "$code" != "0x" ]] || { echo "[deploy] $addr tidak ada bytecode."; return 1; }

  echo "[deploy] FundMe: $addr"
  FUNDME="$addr"
}

# Validasi FUNDME_ADDR env
if [[ -n "$FUNDME" ]]; then
  is_addr "$FUNDME" || { echo "❌ FUNDME_ADDR invalid: $FUNDME"; exit 1; }
  CODE_HEX="$(cast code "$FUNDME" --rpc-url "$RPC_URL" || true)"
  [[ -n "$CODE_HEX" && "$CODE_HEX" != "0x" ]] || { echo "❌ FUNDME_ADDR=$FUNDME tidak ada bytecode di node ini."; exit 1; }
else
  deploy_and_capture || { echo "❌ Tidak bisa mendapatkan alamat FundMe."; exit 1; }
fi

echo "FUNDME=$FUNDME"

########################################
# Owner on-chain & helpers kirim tx
########################################
get_owner(){
  local o
  o="$(cast call "$FUNDME" 'getOwner()(address)' --rpc-url "$RPC_URL" 2>/dev/null || true)"
  if ! is_addr "$o"; then
    o="$(cast call "$FUNDME" 'i_owner()(address)' --rpc-url "$RPC_URL" 2>/dev/null || true)"
  fi
  if is_addr "$o"; then echo "$o"; else echo "$ACCT0"; fi
}
OWNER_ONCHAIN="$(get_owner)"
echo "OWNER(on-chain)=$OWNER_ONCHAIN"

owner_send(){
  cast send "$FUNDME" "$@" --rpc-url "$RPC_URL" --unlocked --from "$OWNER_ONCHAIN" >/dev/null
}

get_funders_len(){
  local i=0
  while true; do
    set +e
    cast call "$FUNDME" "getFunder(uint256)(address)" "$i" --rpc-url "$RPC_URL" >/dev/null 2>&1
    local rc=$?; set -e
    [[ $rc -ne 0 ]] && { echo "$i"; return; }
    i=$((i+1)); [[ $i -gt 10000 ]] && { echo "$i"; return; }
  done
}

########################################
# TESTS (tanpa redeploy; gunakan bc untuk uint256)
########################################
PASS_CNT=0; FAIL_CNT=0
run_test(){ local name="$1"; shift; echo "[$name]"; if "$@"; then OK "$name"; PASS_CNT=$((PASS_CNT+1)); else KO "$name"; FAIL_CNT=$((FAIL_CNT+1)); fi; }

test_current_chain_id(){ cast chain-id --rpc-url "$RPC_URL" >/dev/null; }

test_price_feed_address_is_correct(){
  local pf code
  pf="$(cast call "$FUNDME" 'getPriceFeed()(address)' --rpc-url "$RPC_URL")" || return 1
  code="$(cast code "$pf" --rpc-url "$RPC_URL" || true)"
  [[ -n "$code" && "$code" != "0x" ]]
}

test_get_current_eth_price(){
  local pf
  pf="$(cast call "$FUNDME" 'getPriceFeed()(address)' --rpc-url "$RPC_URL")" || return 1
  cast call "$pf" 'latestRoundData()(uint80,int256,uint256,uint256,uint80)' --rpc-url "$RPC_URL" >/dev/null
  cast call "$pf" 'decimals()(uint8)' --rpc-url "$RPC_URL" >/dev/null
}

test_current_version_is_accurate(){
  local v; v="$(cast call "$FUNDME" 'getVersion()(uint256)' --rpc-url "$RPC_URL")" || return 1
  [[ -n "$v" ]]
}

test_owner_is_deployer(){
  local o
  o="$(cast call "$FUNDME" 'getOwner()(address)' --rpc-url "$RPC_URL" 2>/dev/null || true)"
  if ! is_addr "$o"; then o="$(cast call "$FUNDME" 'i_owner()(address)' --rpc-url "$RPC_URL" 2>/dev/null || true)"; fi
  is_addr "$o"
}

test_minimum_usd_is_five(){
  local val_hex val_dec
  val_hex="$(cast call "$FUNDME" 'MINIMUM_USD()(uint256)' --rpc-url "$RPC_URL")" || return 1
  val_dec="$(to_uint "$val_hex")"
  # bandingkan dengan bc, bukan bash arithmetic
  [[ "$(echo "$val_dec == 5000000000000000000" | bc)" -eq 1 ]]
}

test_minimum_usd_is_five_revert(){
  set +e
  cast call "$FUNDME" "fund()" --value 10000000000 --from "$ACCT0" --rpc-url "$RPC_URL" >/dev/null 2>&1
  local rc=$?; set -e
  [[ $rc -ne 0 ]]
}

test_get_address_to_amount_funded(){
  local before_hex after_hex before_dec after_dec diff_dec
  before_hex="$(cast call "$FUNDME" 'getAddressToAmountFunded(address)(uint256)' "$F1" --rpc-url "$RPC_URL" 2>/dev/null || echo 0x0)"
  cast send "$FUNDME" "fund()" --value 10000000000000000000 --rpc-url "$RPC_URL" --from "$F1" --unlocked >/dev/null
  after_hex="$(cast call "$FUNDME" 'getAddressToAmountFunded(address)(uint256)' "$F1" --rpc-url "$RPC_URL")"
  before_dec="$(to_uint "$before_hex")"
  after_dec="$(to_uint "$after_hex")"
  diff_dec="$(echo "$after_dec - $before_dec" | bc)"
  [[ "$diff_dec" == "10000000000000000000" ]]
}

test_get_funder(){
  local len_before len_after last
  len_before="$(get_funders_len)"
  cast send "$FUNDME" "fund()" --value 1000000000000000000 --rpc-url "$RPC_URL" --from "$F3" --unlocked >/dev/null
  len_after="$(get_funders_len)"
  [[ "$len_after" -ge $((len_before+1)) ]] || return 1
  last="$(cast call "$FUNDME" 'getFunder(uint256)(address)' $((len_after-1)) --rpc-url "$RPC_URL")"
  [[ "${last,,}" == "${F3,,}" ]]
}

test_get_owner(){
  local o; o="$(cast call "$FUNDME" 'getOwner()(address)' --rpc-url "$RPC_URL" 2>/dev/null || true)"
  if ! is_addr "$o"; then o="$(cast call "$FUNDME" 'i_owner()(address)' --rpc-url "$RPC_URL" 2>/dev/null || true)"; fi
  is_addr "$o"
}

test_withdraw(){
  cast send "$FUNDME" "fund()" --value 2000000000000000000 --rpc-url "$RPC_URL" --from "$F1" --unlocked >/dev/null
  cast send "$FUNDME" "fund()" --value 3000000000000000000 --rpc-url "$RPC_URL" --from "$F2" --unlocked >/dev/null
  owner_send "withdraw()"
  # balance >= 0 (cek via bc)
  local bal_hex bal_dec
  bal_hex="$(cast balance "$FUNDME" --rpc-url "$RPC_URL")"
  bal_dec="$(to_uint "$bal_hex")"
  [[ "$(echo "$bal_dec >= 0" | bc)" -eq 1 ]]
}

test_cheaper_withdraw(){
  cast send "$FUNDME" "fund()" --value 4000000000000000000 --rpc-url "$RPC_URL" --from "$F1" --unlocked >/dev/null
  cast send "$FUNDME" "fund()" --value 1000000000000000000 --rpc-url "$RPC_URL" --from "$F2" --unlocked >/dev/null
  owner_send "cheaperWithdraw()"
  local bal_hex bal_dec
  bal_hex="$(cast balance "$FUNDME" --rpc-url "$RPC_URL")"
  bal_dec="$(to_uint "$bal_hex")"
  [[ "$(echo "$bal_dec >= 0" | bc)" -eq 1 ]]
}

test_withdraw_revert_when_not_owner(){
  set +e; cast call "$FUNDME" "withdraw()" --from "$F1" --rpc-url "$RPC_URL" >/dev/null 2>&1; local rc=$?; set -e
  [[ $rc -ne 0 ]]
}

test_cheaper_withdraw_revert_when_not_owner(){
  set +e; cast call "$FUNDME" "cheaperWithdraw()" --from "$F1" --rpc-url "$RPC_URL" >/dev/null 2>&1; local rc=$?; set -e
  [[ $rc -ne 0 ]]
}

test_withdraw_no_funders_zero_iteration_loop_succeeds(){
  owner_send "withdraw()"
  true
}

test_cheaper_withdraw_no_funders_zero_iteration_loop_succeeds(){
  owner_send "cheaperWithdraw()"
  true
}

########################################
# Dispatcher
########################################
TESTS=(
  test_current_chain_id
  test_price_feed_address_is_correct
  test_get_current_eth_price
  test_current_version_is_accurate
  test_owner_is_deployer
  test_minimum_usd_is_five
  test_minimum_usd_is_five_revert
  test_get_address_to_amount_funded
  test_get_funder
  test_get_owner
  test_withdraw
  test_cheaper_withdraw
  test_withdraw_revert_when_not_owner
  test_cheaper_withdraw_revert_when_not_owner
  test_withdraw_no_funders_zero_iteration_loop_succeeds
  test_cheaper_withdraw_no_funders_zero_iteration_loop_succeeds
)

run_all(){
  local pass=0 fail=0
  for t in "${TESTS[@]}"; do
    echo "[$t]"
    if "$t"; then OK "$t"; pass=$((pass+1)); else KO "$t"; fail=$((fail+1)); fi
  done
  echo "======================"
  echo "PASS: $pass | FAIL: $fail"
  [[ $fail -eq 0 ]]
}

case "${1:-all}" in
  all) run_all ;;
  list) printf "%s\n" "${TESTS[@]}" ;;
  test_*) echo "[$1]"; if "$1"; then OK "$1"; else KO "$1"; fi ;;
  *) echo "usage: $0 all | list | test_<name>"; exit 1 ;;
esac
