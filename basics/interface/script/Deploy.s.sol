// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/ICounter.sol";

contract CounterScript is Script {
    function run() external {
        vm.startBroadcast();
        Counter c = new Counter();
        console.log("Deployed to:", address(c));
        vm.stopBroadcast();
    }
}
