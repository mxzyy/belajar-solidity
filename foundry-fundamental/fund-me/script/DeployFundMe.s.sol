// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function deploy() public returns (FundMe, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        address priceFeed = helperConfig.getConfigByChainId(block.chainid).priceFeed;

        console.log("Deploying to chainid:", block.chainid);
        console.log("Using price feed address:", priceFeed);

        vm.startBroadcast();
        fundMe = new FundMe(priceFeed);
        vm.stopBroadcast();
        console.log("FundMe deployed at:", address(fundMe));
        return (fundMe, helperConfig);
    }

    function run() external returns (FundMe, HelperConfig) {
        return deploy();
    }
}
