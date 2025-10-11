// SPDX-License-Identifier: UNCLICENSED
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";

/**
 * @title A script for deploying Raffle contract
 * @author mxzyy
 * @notice This script is for deploying Raffle contract
 * @dev This implements the Script from forge-std
 */
contract DeployRaffle is Script {
    function run() external {
        uint256 subscriptionId = vm.envUint("SUBSCRIPTION_ID");
        bytes32 gasLane = vm.envBytes32("GAS_LANE");
        uint256 interval = vm.envUint("INTERVAL");
        uint256 entranceFee = vm.envUint("ENTRANCE_FEE");
        uint256 rawcallbackGasLimit = vm.envUint("CALLBACK_GAS_LIMIT");
        require(rawcallbackGasLimit <= type(uint32).max, "CALLBACK_GAS_LIMIT too large");
        uint32 callbackGasLimit = uint32(rawcallbackGasLimit);
        address vrfCoordinatorV2 = vm.envAddress("VRF_COORDINATOR");
        vm.startBroadcast();
        new Raffle(subscriptionId, gasLane, interval, entranceFee, callbackGasLimit, vrfCoordinatorV2);
        vm.stopBroadcast();
    }
}
