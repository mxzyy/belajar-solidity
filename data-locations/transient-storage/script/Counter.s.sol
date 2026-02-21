// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TStore} from "../src/TStore.sol";

contract CounterScript is Script {
    function run() external {
        vm.startBroadcast();
        TStore tsc = new TStore();
        console.log("Deployed to:", address(tsc));
        vm.stopBroadcast();
    }
}
