// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";

contract DeployTokenScript is Script {
    Token public token;
    address public deployer;

    function run() public {
        vm.startBroadcast();
        deployer = tx.origin;
        token = new Token("Token", "TK");
        vm.stopBroadcast();
    }
}
