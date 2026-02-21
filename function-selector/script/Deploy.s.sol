// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {SelectorGateway} from "../src/FS.sol";

contract FSScript is Script {
    // admin
    address internal admin = address(0xAd13);

    function run() external {
        vm.startBroadcast();
        SelectorGateway sg = new SelectorGateway(admin);
        console.log("Deployed to:", address(sg));
        vm.stopBroadcast();
    }
}
