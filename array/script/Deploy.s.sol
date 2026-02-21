// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Array} from "../src/Array.sol";

contract Deployscript is Script {
    Array public arrayContract;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        arrayContract = new Array();

        vm.stopBroadcast();
    }
}
