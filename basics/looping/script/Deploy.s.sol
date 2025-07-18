// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Looping} from "../src/Looping.sol";

contract LoopingScript is Script {
    Looping public looping;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        looping = new Looping();

        vm.stopBroadcast();
    }
}
