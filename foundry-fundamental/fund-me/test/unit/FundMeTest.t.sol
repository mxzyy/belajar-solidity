// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {HelperConfig, CodeConstant} from "../../script/HelperConfig.s.sol";

/// @title FundMeTest
/// @notice Unit tests for the `FundMe` contract.
/// @dev Uses Foundry's `Test` utilities and `HelperConfig` to resolve the correct price feed per chain.
contract FundMeTest is Test, CodeConstant {
    /// @notice Deployed instance of the contract under test.
    FundMe public fundMeContract;

    /// @notice Helper that provides per-network configuration (e.g., price feed address).
    HelperConfig public helperConfig;

    /// @notice Active network configuration selected based on `block.chainid`.
    HelperConfig.NetworkConfig public networkConfig;

    /// @notice Test fixture setup: resolves network config and deploys `FundMe`.
    /// @dev Called automatically by Foundry before each test case.
    function setUp() external {
        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getConfigByChainId(block.chainid);
        fundMeContract = new FundMe(networkConfig.priceFeed);
    }

    /// @notice Verifies that `FundMe` stores the expected price feed address for the current chain.
    /// @dev Read-only assertion; diagnostic logs are printed for visibility.
    function testPriceFeedAddressIsCorrect() public view {
        address priceFeed = address(fundMeContract.getPriceFeed());
        console.log("Price Feed: ", priceFeed);
        console.log("Network Price Feed: ", networkConfig.priceFeed);
        assert(priceFeed == networkConfig.priceFeed);
    }

    /// @notice Verifies that the price feed version exposed by `FundMe` equals 4.
    /// @dev Adjust the expected value if the underlying aggregator/version changes.
    function testCurrentVersionIsAccurate() public view {
        uint256 version = fundMeContract.getVersion();
        console.log("Version: ", version);
        assert(version == 4);
    }

    /// @notice Verifies the owner of the deployed `FundMe` contract is the test contract.
    /// @dev The test contract is the deployer in the `setUp` function.
    function testOwnerIsDeployer() public view {
        address owner = fundMeContract.i_owner();
        console.log("Owner: ", owner);
        assert(owner == address(this)); // The test contract is the deployer
    }

    /// @notice Verifies that the minimum USD constant in `FundMe` equals 5e18.
    /// @dev Read-only assertion; diagnostic logs are printed for visibility.
    function testMinimumUsdIsFive() public view {
        uint256 minimumUsd = fundMeContract.MINIMUM_USD();
        console.log("Minimum USD: ", minimumUsd);
        assert(minimumUsd == 5e18);
    }

    /// @notice Verifies that funding with less than the minimum USD amount reverts.
    /// @dev The minimum USD is 5e18, which is approximately 0.
    function testMinimunUsdIsFiveRevert() public {
        vm.expectRevert();
        fundMeContract.fund{value: 1e10}(); // 0.1 ETH
    }

    function testWithdraw() public {
        address owner = address(0xABCD);
        address funder_1 = address(1);
        address funder_2 = address(2);

        vm.prank(owner);
        // vm.deal(owner, 1e18);
        fundMeContract = new FundMe(networkConfig.priceFeed);
        console.log("Starting balance of contract:", address(fundMeContract).balance);

        vm.prank(funder_1);
        vm.deal(funder_1, 10e18);
        fundMeContract.fund{value: 10e18}();

        console.log("Created funder 1 with address:", funder_1);
        console.log("Funder 1 funded with 10 ETH");
        console.log("Balance of contract after funder 1:", address(fundMeContract).balance);

        vm.prank(funder_2);
        vm.deal(funder_2, 10e18);
        fundMeContract.fund{value: 10e18}();

        console.log("Created funder 2 with address:", funder_2);
        console.log("Funder 2 funded with 10 ETH");
        console.log("Balance of contract after funder 2:", address(fundMeContract).balance);

        uint256 startingOwnerBalance = fundMeContract.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMeContract).balance;

        vm.prank(fundMeContract.getOwner());
        fundMeContract.withdraw();

        console.log("Owner withdrew funds");
        console.log("Balance of contract after withdraw:", address(fundMeContract).balance);
        console.log("Owner balance after withdraw:", fundMeContract.getOwner().balance);

        uint256 endingOwnerBalance = fundMeContract.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMeContract).balance;

        assert(endingFundMeBalance == 0);
        assert(endingOwnerBalance == startingOwnerBalance + startingFundMeBalance);
    }
}
