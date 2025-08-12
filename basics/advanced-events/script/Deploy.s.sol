// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {AE} from "../src/AE.sol";

contract CounterScript is Script {
    function run() external {
        vm.startBroadcast();
        AE ae = new AE();
        console.log("Deployed to:", address(ae));
        vm.stopBroadcast();
    }
}
