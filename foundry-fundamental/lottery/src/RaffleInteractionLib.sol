// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {HelperConfig} from "../script/HelperConfig.s.sol";

library FundSubscriptionLib {
    struct FundParams {
        address vrfCoordinatorV2_5;
        uint256 subId;
        address link;
        address account;
    }

    function prepareFundParams(HelperConfig.NetworkConfig memory cfg) internal pure returns (FundParams memory) {
        if (cfg.subscriptionId == 0) {
            revert("TODO: handle create sub di sini atau di luar");
        }

        return FundParams({
            vrfCoordinatorV2_5: cfg.vrfCoordinatorV2_5,
            subId: cfg.subscriptionId,
            link: cfg.link,
            account: cfg.account
        });
    }
}

library FundLogic {
    function isLocal(uint256 chainId, uint256 localChainId) internal pure returns (bool) {
        return chainId == localChainId;
    }
}
