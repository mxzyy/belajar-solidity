#!/bin/bash

RPC_URL="http://127.0.0.1:8545"
ANVIL_PID=""
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

# Cleanup: kill anvil saat script selesai atau di-cancel (Ctrl+C)
cleanup() {
    if [ -n "$ANVIL_PID" ]; then
        echo ""
        echo "Shutting down Anvil (PID: $ANVIL_PID)..."
        kill $ANVIL_PID 2>/dev/null
        wait $ANVIL_PID 2>/dev/null
    fi
}
trap cleanup EXIT

# 1. Start Anvil
echo "Starting Anvil..."
anvil --silent &
ANVIL_PID=$!
sleep 2

# Check apakah anvil berhasil jalan
if ! kill -0 $ANVIL_PID 2>/dev/null; then
    echo "Error: Anvil gagal start. Mungkin port 8545 sudah dipakai?"
    exit 1
fi
echo "Anvil running (PID: $ANVIL_PID)"

# 2. Deploy contract
echo "Deploying Primitives contract..."
DEPLOY_OUTPUT=$(forge create src/Primitives.sol:Primitives \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast 2>&1)

CONTRACT_ADDR=$(echo "$DEPLOY_OUTPUT" | grep "Deployed to:" | awk '{print $3}')

if [ -z "$CONTRACT_ADDR" ]; then
    echo "Error: Deploy gagal!"
    echo "$DEPLOY_OUTPUT"
    exit 1
fi
echo "Contract deployed at: $CONTRACT_ADDR"
echo ""

# 3. Helper functions
decode_and_display() {
    local func_name="$1"
    local data_type="$2"

    echo "=== Testing $func_name() ==="
    RESULT=$(cast call $CONTRACT_ADDR "$func_name()" --rpc-url $RPC_URL)
    echo "Raw hex: $RESULT"

    case $data_type in
        "bool")
            DECODED=$(cast --to-dec $RESULT)
            if [ "$DECODED" = "1" ]; then
                echo "Decoded: true"
            else
                echo "Decoded: false"
            fi
            ;;
        "uint")
            echo "Decoded: $(cast --to-dec $RESULT)"
            ;;
        "int")
            echo "Decoded int8: $(decode_int8 $RESULT)"
            ;;
        "address")
            # Ambil 40 karakter terakhir dari hex (20 bytes address)
            RAW=$(echo $RESULT | sed 's/0x//')
            ADDR="0x${RAW: -40}"
            echo "Decoded: $(cast --to-checksum-address $ADDR)"
            ;;
        "bytes1")
            BYTES1=$(echo $RESULT | cut -c1-4)
            echo "Decoded: $BYTES1"
            echo "As decimal: $(cast --to-dec $BYTES1)"
            ;;
    esac
    echo ""
}

decode_int8() {
    local hex_value="$1"
    local last_byte="${hex_value: -2}"
    local unsigned_val=$(printf "%d" "0x$last_byte")

    if [ $unsigned_val -gt 127 ]; then
        local signed_val=$((unsigned_val - 256))
        echo $signed_val
    else
        echo $unsigned_val
    fi
}

# 4. Run all tests
decode_and_display "boo" "bool"
decode_and_display "u8" "uint"
decode_and_display "u256" "uint"
decode_and_display "u" "uint"
decode_and_display "i8" "int"
decode_and_display "i256" "int"
decode_and_display "i" "int"
decode_and_display "minInt" "int"
decode_and_display "maxInt" "int"
decode_and_display "addr" "address"
decode_and_display "a" "bytes1"
decode_and_display "b" "bytes1"
decode_and_display "defaultBoo" "bool"
decode_and_display "defaultUint" "uint"
decode_and_display "defaultInt" "int"
decode_and_display "defaultAddr" "address"

echo "Done!"
