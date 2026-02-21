// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {FunctionGallery} from "../src/FunctionGallery.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();
        FunctionGallery fgc = new FunctionGallery(0);
        console.log("Deployed to:", address(fgc));
        vm.stopBroadcast();
    }
}
