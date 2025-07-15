// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {fixedVariable} from "../src/fixedVariable.sol";

contract fixedVariableScript is Script {
    fixedVariable public fixedVar;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        fixedVar = new fixedVariable();

        vm.stopBroadcast();
    }
}
