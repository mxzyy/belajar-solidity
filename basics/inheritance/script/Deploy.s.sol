// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {OwnerCounter} from "../src/Counter.sol";

contract InheritScript is Script {
    function run() external {
        vm.startBroadcast();
        OwnerCounter ic = new OwnerCounter();
        console.log("Deployed to:", address(ic));
        vm.stopBroadcast();
    }
}
