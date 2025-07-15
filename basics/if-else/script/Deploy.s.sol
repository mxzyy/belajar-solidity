// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IfElse} from "../src/IfElse.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();
        IfElse if_else = new IfElse();
        console.log("Deployed to:", address(if_else));
        vm.stopBroadcast();
    }
}
