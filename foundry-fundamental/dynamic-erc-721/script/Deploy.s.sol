// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DynamicNFT} from "../src/DNFT.sol";

contract DynamicNFTScript is Script {
    DynamicNFT public dynamicNFT;

    function setUp() public returns (DynamicNFT) {
        vm.startBroadcast();
        dynamicNFT = new DynamicNFT();
        vm.stopBroadcast();
        return dynamicNFT;
    }
}
