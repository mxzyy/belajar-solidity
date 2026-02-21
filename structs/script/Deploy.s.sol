// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TokenRegistry} from "../src/TokenRegistry.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();
        TokenRegistry trContract = new TokenRegistry();
        console.log("Deployed to:", address(trContract));
        vm.stopBroadcast();
    }
}
