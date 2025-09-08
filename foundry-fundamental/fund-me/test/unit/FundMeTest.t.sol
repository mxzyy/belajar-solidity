// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {HelperConfig, CodeConstant} from "../../script/HelperConfig.s.sol";

contract FundMeTest is Test, CodeConstant {
    FundMe public fundMeContract;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;

    function setUp() external {
        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getConfigByChainId(block.chainid);
        fundMeContract = new FundMe(networkConfig.priceFeed);
    }

    function testPriceFeedAddressIsCorrect() public view {
        address priceFeed = address(fundMeContract.getPriceFeed());
        console.log("Price Feed: ", priceFeed);
        console.log("Network Price Feed: ", networkConfig.priceFeed);
        assert(priceFeed == networkConfig.priceFeed);
    }

    function testCurrentVersionIsAccurate() public view {
        uint256 version = fundMeContract.getVersion();
        console.log("Version: ", version);
        assert(version == 4);
    }
}
