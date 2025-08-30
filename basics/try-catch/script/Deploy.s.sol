// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/TC.sol";

// Optional mock untuk testing external call di environment dev.
// Kalau tidak diperlukan di prod, variabel DEPLOY_MOCK_TARGET=false saja.
contract MockTarget is ITarget {
    uint256 public lastValue;

    receive() external payable {
        lastValue += msg.value;
    }

    function risky(uint256 x) external payable override returns (uint256) {
        lastValue += msg.value;
        if (x == 0) revert("x=0 not allowed");
        if (x == 1) {
            uint256 y = 0;
            return 1 / y; // Panic
        }
        return x + 1;
    }
}

contract DeployTC is Script {
    // Output addresses
    address public tc;
    address public mockTarget;

    function run() external {
        // ───── Load ENV ──────────────────────────────────────────────────────────
        // .env keys expected:
        //   PRIVATE_KEY=0xabc...
        //   RPC_URL=... (biasanya ditaruh saat forge script ..., --rpc-url $RPC_URL)
        //   OPERATORS=0x111...,0x222...   (opsional, CSV)
        //   DEPLOY_MOCK_TARGET=true|false (opsional, default=false)
        uint256 deployerPk = vm.envUint("PRIVATE_KEY");

        // Baca operators CSV (opsional). Jika var belum ada → return empty array.
        address[] memory operators = _parseOperatorsEnv("OPERATORS");

        bool deployMock = _readBoolEnvOrDefault("DEPLOY_MOCK_TARGET", false);

        // ───── Start Broadcast ───────────────────────────────────────────────────
        vm.startBroadcast(deployerPk);

        // Deploy TC (owner = msg.sender yang melakukan broadcast)
        TC tcContract = new TC();
        tc = address(tcContract);

        // Optional: deploy MockTarget untuk skenario dev
        if (deployMock) {
            MockTarget mt = new MockTarget();
            mockTarget = address(mt);
        }

        // Set operators jika di-provide
        for (uint256 i = 0; i < operators.length; i++) {
            if (operators[i] != address(0)) {
                tcContract.setOperator(operators[i], true);
            }
        }

        vm.stopBroadcast();

        // ───── Logs ─────────────────────────────────────────────────────────────
        _logSummary(tcContract, operators);
    }

    // ───────────────────────────────────────────────────────────────────────────
    // Helpers
    // ───────────────────────────────────────────────────────────────────────────

    function _parseOperatorsEnv(string memory key) internal view returns (address[] memory list) {
        // Kalau env key tidak diset, kembalikan array kosong
        if (!vm.envExists(key)) {
            list = new address[](0);
            return list;
        }

        // forge dapat parse langsung array address dari JSON:
        // contoh: OPERATORS='["0xAbc...","0xDef..."]'
        // Namun seringnya orang pakai CSV, maka kita dukung CSV → JSON adapter.
        string memory raw = vm.envString(key);

        // Cek apakah sudah JSON array (berawalan '['). Jika ya → parse langsung.
        bytes memory b = bytes(raw);
        if (b.length > 0 && b[0] == "[") {
            list = vm.parseJsonAddressArray(string.concat("{\"ops\":", raw, "}"), ".ops");
            return list;
        }

        // Kalau CSV, ubah ke JSON array string terlebih dahulu.
        string memory jsonArray = _csvAddressesToJson(raw);
        list = vm.parseJsonAddressArray(string.concat("{\"ops\":", jsonArray, "}"), ".ops");
    }

    function _csvAddressesToJson(string memory csv) internal pure returns (string memory) {
        bytes memory src = bytes(csv);
        bytes memory out = "[";
        uint256 len = src.length;

        string memory current = "";
        for (uint256 i = 0; i < len; i++) {
            bytes1 c = src[i];
            if (c == "," || c == " ") {
                if (bytes(current).length > 0) {
                    out = abi.encodePacked(out, _wrapAddr(current), ",");
                    current = "";
                }
            } else {
                current = string(abi.encodePacked(bytes(current), c));
            }
        }
        if (bytes(current).length > 0) {
            out = abi.encodePacked(out, _wrapAddr(current));
        } else {
            // trim trailing comma if any
            if (out.length > 1 && out[out.length - 1] == ",") {
                bytes memory tmp = new bytes(out.length - 1);
                for (uint256 j = 0; j < out.length - 1; j++) {
                    tmp[j] = out[j];
                }
                out = tmp;
            }
        }
        out = abi.encodePacked(out, "]");
        return string(out);
    }

    function _wrapAddr(string memory a) internal pure returns (string memory) {
        // Normalize: jika tidak diawali 0x, biarkan—Foundry akan validasi saat parse
        // Bungkus dalam quotes untuk JSON
        return string(abi.encodePacked("\"", a, "\""));
    }

    function _readBoolEnvOrDefault(string memory key, bool deflt) internal view returns (bool) {
        if (!vm.envExists(key)) return deflt;
        string memory v = vm.envString(key);
        bytes32 h = keccak256(bytes(_lower(v)));
        if (h == keccak256("true") || h == keccak256("1") || h == keccak256("yes")) return true;
        if (h == keccak256("false") || h == keccak256("0") || h == keccak256("no")) return false;
        return deflt;
    }

    function _lower(string memory s) internal pure returns (string memory) {
        bytes memory b = bytes(s);
        for (uint256 i = 0; i < b.length; i++) {
            if (b[i] >= 0x41 && b[i] <= 0x5A) b[i] = bytes1(uint8(b[i]) + 32);
        }
        return string(b);
    }

    function _logSummary(TC tcContract, address[] memory operators) internal view {
        console2.log("==== Deploy Summary ====");
        console2.log("deployer:", tx.origin);
        console2.log("CHAIN_ID:", block.chainid);
        console2.log("TC:", address(tcContract));
        if (mockTarget != address(0)) {
            console2.log("MockTarget:", mockTarget);
        }
        console2.log("owner(TC):", tcContract.owner());
        console2.log("operators set:", operators.length);
        for (uint256 i = 0; i < operators.length; i++) {
            bool on = tcContract.operator(operators[i]);
            console2.log("  -", operators[i], on ? "ENABLED" : "DISABLED");
        }
        console2.log("========================");
    }
}
