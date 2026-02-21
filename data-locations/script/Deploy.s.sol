// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DL} from "../src/DL.sol";

contract CounterScript is Script {
    function run() external {
        vm.startBroadcast();
        DL dlc = new DL();
        console.log("Deployed to:", address(dlc));
        vm.stopBroadcast();
    }
}
