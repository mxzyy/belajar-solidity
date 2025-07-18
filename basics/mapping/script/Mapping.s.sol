// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Mapping} from "../src/Mapping.sol";

contract MappingScript is Script {
    Mapping public mappingContract;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        mappingContract = new Mapping();

        vm.stopBroadcast();
    }
}
