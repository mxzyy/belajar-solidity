// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {UDVT} from "../src/UDVT.sol";

contract UDVTScript is Script {
    function run() external {
        vm.startBroadcast();
        UDVT udvtContract = new UDVT();
        console.log("Deployed to:", address(udvtContract));
        vm.stopBroadcast();
    }
}
