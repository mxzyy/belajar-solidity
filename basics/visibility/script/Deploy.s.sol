// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {VisibilityDemo} from "../src/VD.sol";

contract CounterScript is Script {
    function run() external {
        vm.startBroadcast();
        VisibilityDemo VDC = new VisibilityDemo();
        console.log("Deployed to:", address(VDC));
        vm.stopBroadcast();
    }
}
