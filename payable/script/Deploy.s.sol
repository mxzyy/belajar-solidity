// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {PayableDemo} from "../src/PD.sol";

contract PayableDemoScript is Script {
    function run() external {
        // Opsi A (pakai env var): export PRIVATE_KEY=0x....
        // uint256 key = vm.envUint("PRIVATE_KEY");
        // vm.startBroadcast(key);

        // Opsi B (default): pakai FOUNDRY_PRIVATE_KEY dari foundry
        vm.startBroadcast();

        PayableDemo demo = new PayableDemo();
        console2.log("PayableDemo deployed at:", address(demo));

        vm.stopBroadcast();
    }
}
