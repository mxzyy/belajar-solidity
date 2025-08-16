// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SimpleFallback} from "../src/Fallback.sol";

contract CounterScript is Script {
    function run() external {
        vm.startBroadcast();
        SimpleFallback sf = new SimpleFallback();
        console.log("Deployed to:", address(sf));
        vm.stopBroadcast();
    }
}
