// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// --- External Imports ---
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    /// @notice Functions
    // --- Functions ---

    /// @notice Get the latest price from the price feed
    /// @dev This function retrieves the latest price from the provided AggregatorV3Interface
    /// @param priceFeed The address of the price feed contract
    /// @return The latest price as a uint256
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 answer,,,) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 1e10);
    }

    /// @notice Convert ETH amount to USD
    /// @dev This function converts the given ETH amount to its equivalent USD value using the price feed
    /// @param ethAmount The amount of ETH to convert
    /// @param priceFeed The address of the price feed contract
    /// @return The equivalent USD value as a uint256
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}
