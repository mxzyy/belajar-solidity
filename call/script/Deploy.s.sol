// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {A, B} from "../src/Call.sol";

contract CounterScript is Script {
    function run() external {
        vm.startBroadcast();
        A ac = new A();
        console.log("Deployed to:", address(ac));

        B bc = new B();
        console.log("Deployed to:", address(bc));
        vm.stopBroadcast();
    }
}
