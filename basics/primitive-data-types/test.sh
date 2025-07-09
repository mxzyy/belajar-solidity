#!/bin/bash

CONTRACT_ADDR="0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
RPC_URL="http://127.0.0.1:8545"

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
            echo "Decoded: $(cast --to-checksum-address $RESULT)"
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
    # Ambil 2 karakter terakhir (1 byte untuk int8)
    local last_byte="${hex_value: -2}"
    
    # Convert hex ke decimal
    local unsigned_val=$(printf "%d" "0x$last_byte")
    
    # Check jika negative (bit tertinggi = 1)
    if [ $unsigned_val -gt 127 ]; then
        # Two's complement: subtract dari 256
        local signed_val=$((unsigned_val - 256))
        echo $signed_val
    else
        echo $unsigned_val
    fi
}

# Run all tests with decoding
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
