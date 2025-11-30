// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {codeConstants} from "./HelperConfig.s.sol";
import {FundSubscriptionLib, FundLogic} from "../src/RaffleInteractionLib.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinatorV2_5 = helperConfig.getConfigByChainId(block.chainid).vrfCoordinatorV2_5;
        address account = helperConfig.getConfigByChainId(block.chainid).account;
        return createSubscription(vrfCoordinatorV2_5, account);
    }

    function createSubscription(address vrfCoordinatorV2_5, address account) public returns (uint256, address) {
        console.log("Creating subscription on chainId: ", block.chainid);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription Id is: ", subId);
        console.log("Please update the subscriptionId in HelperConfig.s.sol");
        return (subId, vrfCoordinatorV2_5);
    }

    function run() external returns (uint256, address) {
        return createSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(address contractToAddToVrf, address vrfCoordinator, uint256 subId, address account) public {
        console.log("Adding consumer contract: ", contractToAddToVrf);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddToVrf);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinatorV2_5 = helperConfig.getConfig().vrfCoordinatorV2_5;
        address account = helperConfig.getConfig().account;

        addConsumer(mostRecentlyDeployed, vrfCoordinatorV2_5, subId, account);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}

contract FundSubscription is codeConstants, Script {
    uint96 public constant FUND_AMOUNT = 0.01 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory cfg = helperConfig.getOrCreateAnvilEthConfig();
        FundSubscriptionLib.FundParams memory params = FundSubscriptionLib.prepareFundParams(cfg);

        fundSubscription(params.vrfCoordinatorV2_5, params.subId, params.link, params.account);
    }

    function fundSubscription(address vrfCoordinatorV2_5, uint256 subId, address link, address account) public {
        console.log("Funding subscription: ", subId);
        console.log("Using vrfCoordinator: ", vrfCoordinatorV2_5);
        console.log("On ChainID: ", block.chainid);
        console.log("Account: ", account);
        bool local = FundLogic.isLocal(block.chainid, LOCAL_CHAIN_ID);
        if (local) {
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fundSubscription(subId, 100 ether);
            vm.stopBroadcast();
        } else {
            console.log(LinkToken(link).balanceOf(msg.sender));
            console.log(msg.sender);
            console.log(LinkToken(link).balanceOf(address(this)));
            console.log(address(this));
            vm.startBroadcast(account);
            LinkToken(link).transferAndCall(vrfCoordinatorV2_5, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}
