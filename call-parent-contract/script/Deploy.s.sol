// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {D} from "../src/Linearization.sol";

contract CounterScript is Script {
    function run() external {
        vm.startBroadcast();
        D dc = new D();
        console.log("Deployed to:", address(dc));
        vm.stopBroadcast();
    }
}
