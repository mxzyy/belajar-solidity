// SPDX-License-Identifier: UNCLICENSED
pragma solidity ^0.8.20;

import {HelperConfig} from "../script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription} from "../script/Interactions.s.sol";

/**
 * @title A library for Raffle deployment related functions
 * @author mxzyy
 * @notice This library is for Raffle deployment related functions
 * @dev This library is used to avoid code duplication in deployment scripts and tests
 */
library RaffleDeployerLib {
    function prepareConfig(HelperConfig.NetworkConfig memory config)
        internal
        returns (HelperConfig.NetworkConfig memory)
    {
        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinatorV2_5) =
                createSubscription.createSubscription(config.vrfCoordinatorV2_5, config.account);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinatorV2_5, config.subscriptionId, config.link, config.account
            );
        }
        return config;
    }

    function prepareRawCallbackGasLimit(uint256 rawCallbackGasLimit) internal pure returns (uint32) {
        require(rawCallbackGasLimit <= type(uint32).max, "CALLBACK_GAS_LIMIT too large");
        return uint32(rawCallbackGasLimit);
    }
}
