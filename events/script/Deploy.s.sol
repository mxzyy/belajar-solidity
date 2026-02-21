// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Events} from "../src/Events.sol";

contract EventsScript is Script {
    function run() external {
        vm.startBroadcast();
        Events ec = new Events();
        console.log("Deployed to:", address(ec));
        vm.stopBroadcast();
    }
}
