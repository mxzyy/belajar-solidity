// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

/// @title DeployFundMe
/// @notice Deployment helper for FundMe with explicit owner control for tests and scripts.
/// @dev Use `deploy(false, owner)` in tests (no broadcast) to make the constructor sender an EOA.
///      Use `deploy(true, owner)` or `run()` with forge script for real broadcasts.
contract DeployFundMe is Script {
    /// @notice Deploy FundMe and return both the instance and the HelperConfig used.
    /// @param doBroadcast When true, wraps deployment in vm.startBroadcast/stopBroadcast.
    /// @param desiredOwner If non-zero:
    ///        - non-broadcast mode: we `vm.prank(desiredOwner)` so constructor sender is this EOA.
    ///        - broadcast mode: we `vm.startBroadcast(desiredOwner)` so tx sender is this EOA.
    ///        If zero, defaults to the script's sender.
    /// @return fund The deployed FundMe instance.
    /// @return cfg  The HelperConfig instance that resolved the price feed for the current chain.
    function deploy(bool doBroadcast, address desiredOwner) public returns (FundMe fund, HelperConfig cfg) {
        cfg = new HelperConfig();
        address priceFeed = cfg.getConfigByChainId(block.chainid).priceFeed;

        console.log("Deploying FundMe to chainId:", block.chainid);
        console.log("Using price feed address:", priceFeed);
        console.log("Desired owner:", desiredOwner);

        if (doBroadcast) {
            // Broadcast path (forge script)
            if (desiredOwner != address(0)) {
                vm.startBroadcast(desiredOwner);
            } else {
                vm.startBroadcast();
            }
            fund = new FundMe(priceFeed);
            vm.stopBroadcast();
        } else {
            // Test path (no broadcast). Make constructor sender an EOA.
            if (desiredOwner != address(0)) {
                vm.prank(desiredOwner); // affects next call only, no need to stopPrank
            }
            fund = new FundMe(priceFeed);
        }

        console.log("FundMe deployed at:", address(fund));
    }

    /// @notice Entry point for real broadcasts from forge script.
    /// @dev Uses the script's default broadcaster (from env) unless you pass a sender via deploy().
    function run() external returns (FundMe fund, HelperConfig cfg) {
        return deploy(true, address(0));
    }
}
