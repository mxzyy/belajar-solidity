// SPDX-License-Identifier: MIT

// Wajib VM sepolia buat ambil data 
pragma solidity ^0.8.26;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract getDataFeed {
    function getETH_price() view public returns (int) {
        AggregatorV3Interface ETH_datafeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (,int answer,,,) = ETH_datafeed.latestRoundData();
        return answer;
    }

    function getETH_version() view public returns (uint) {
        AggregatorV3Interface ETH_datafeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return ETH_datafeed.version();
    }
}