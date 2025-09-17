// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {DevOpsTools} from "foundry-devops/DevOpsTools.sol";

contract FundMe_Fund_InteractionContract is Script {
    uint256 constant SEND_VALUE = 0.1 ether;

    function FundMe_Fund_Interaction(address recentCA) public {
        vm.startBroadcast();
        FundMe(payable(recentCA)).fund{value: SEND_VALUE}();
        console.log("Funded FundMe contract with %s", SEND_VALUE);
        vm.stopBroadcast();
    }

    function run() external {
        address recentCA = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        FundMe_Fund_Interaction(recentCA);
    }
}

contract FundMe_Withdraw_InteractionContract is Script {
    function FundMe_Withdraw_Interaction(address recentCA) public {
        vm.startBroadcast();
        FundMe(payable(recentCA)).withdraw();
        console.log("Withdrew from FundMe contract");
        vm.stopBroadcast();
    }

    function run() external {
        address recentCA = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        FundMe_Withdraw_Interaction(recentCA);
    }
}
