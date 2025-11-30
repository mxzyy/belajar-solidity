// SPDX-License-Identifier: UNCLICENSED
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {AddConsumer, FundSubscription} from "./Interactions.s.sol";
import {RaffleDeployerLib} from "../src/RaffleDeployerLib.sol";

/**
 * @title A script for deploying Raffle contract
 * @author mxzyy
 * @notice This script is for deploying Raffle contract
 * @dev This implements the Script from forge-std
 */
contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        AddConsumer addConsumer = new AddConsumer();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        config = RaffleDeployerLib.prepareConfig(config);
        FundSubscription fundSubscription = new FundSubscription();
        uint256 subscriptionId = config.subscriptionId;
        bytes32 gasLane = config.gasLane;
        uint256 interval = config.automationUpdateInterval;
        uint256 entranceFee = config.raffleEntranceFee;
        uint256 rawcallbackGasLimit = config.callbackGasLimit;
        uint32 callbackGasLimit = RaffleDeployerLib.prepareRawCallbackGasLimit(rawcallbackGasLimit);
        address vrfCoordinatorV2 = config.vrfCoordinatorV2_5;
        vm.startBroadcast();
        Raffle raffleContract =
            new Raffle(subscriptionId, gasLane, interval, entranceFee, callbackGasLimit, vrfCoordinatorV2);
        vm.stopBroadcast();

        addConsumer.addConsumer(
            address(raffleContract), config.vrfCoordinatorV2_5, config.subscriptionId, config.account
        );
        fundSubscription.fundSubscription(config.vrfCoordinatorV2_5, config.subscriptionId, config.link, config.account);
        return (raffleContract, helperConfig);
    }
}
