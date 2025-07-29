// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Enum} from "../src/Enum.sol";

contract EnumScript is Script {
    function run() external {
        vm.startBroadcast();
        Enum enumContract = new Enum();
        console.log("Deployed to:", address(enumContract));
        vm.stopBroadcast();
    }
}
