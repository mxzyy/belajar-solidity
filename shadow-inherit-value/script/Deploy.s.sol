// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SIV_Child} from "../src/SIV.sol";

contract CounterScript is Script {
    function run() external {
        vm.startBroadcast();
        SIV_Child c = new SIV_Child();
        console.log("Deployed to:", address(c));
        vm.stopBroadcast();
    }
}
