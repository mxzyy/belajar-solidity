// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {HelperConfig, CodeConstant} from "../../script/HelperConfig.s.sol";

/// @title FundMeTest
/// @notice Unit tests for the `FundMe` contract.
/// @dev Uses Foundry's `Test` utilities and `HelperConfig` to resolve the correct price feed per chain.
/// @custom:framework Foundry (forge-std)
contract FundMeTest is Test, CodeConstant {
    /// @notice Deployed instance of the contract under test.
    /// @dev Assigned in {setUp}.
    FundMe public fundMeContract;

    /// @notice Helper that provides per-network configuration (e.g., price feed address).
    /// @dev Deployed in {setUp} and used to derive {networkConfig}.
    HelperConfig public helperConfig;

    /// @notice Active network configuration selected based on `block.chainid`.
    /// @dev Retrieved from {HelperConfig.getConfigByChainId}.
    HelperConfig.NetworkConfig public networkConfig;

    /// @notice Test fixture setup: resolves network configuration and deploys `FundMe`.
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

    /// @notice Verifies the owner of the deployed `FundMe` contract is the test contract (this contract).
    /// @dev The test contract is the deployer in {setUp}, therefore should be the owner.
    function testOwnerIsDeployer() public view {
        address owner = fundMeContract.i_owner();
        console.log("Owner: ", owner);
        assert(owner == address(this)); // The test contract is the deployer
    }

    /// @notice Verifies that the minimum USD constant in `FundMe` equals 5e18 (scaled to 18 decimals).
    /// @dev Read-only assertion; diagnostic logs are printed for visibility.
    function testMinimumUsdIsFive() public view {
        uint256 minimumUsd = fundMeContract.MINIMUM_USD();
        console.log("Minimum USD: ", minimumUsd);
        assert(minimumUsd == 5e18);
    }

    /// @notice Verifies that funding below the minimum USD threshold reverts.
    /// @dev Uses a small `msg.value` to trigger the "minimum 5 USD" revert path.
    function testMinimunUsdIsFiveRevert() public {
        vm.expectRevert();
        fundMeContract.fund{value: 1e10}(); // intentionally tiny amount (1e10 wei) to force revert
    }

    /// @notice Verifies that the internal mapping `addressToAmountFunded` records the sent value for a funder.
    /// @dev Deals balance to `funder`, performs a fund call, and checks the recorded amount.
    function testGetAddressToAmountFunded() public {
        address funder = address(1);
        vm.prank(funder);
        vm.deal(funder, 10e18);
        console.log("Funder balance: ", funder.balance);
        console.log("Contract balance before fund: ", address(fundMeContract).balance);

        fundMeContract.fund{value: 10e18}();

        console.log("Funder balance after fund: ", funder.balance);
        console.log("Contract balance: ", address(fundMeContract).balance);

        uint256 amountFunded = fundMeContract.getAddressToAmountFunded(funder);
        assert(amountFunded == 10e18);
    }

    /// @notice Verifies that the first funder recorded by the contract matches the address that funded.
    /// @dev Funds once from `funder` and checks `getFunder(0)`.
    function testGetFunder() public {
        address funder = address(1);
        vm.prank(funder);
        vm.deal(funder, 10e18);
        fundMeContract.fund{value: 10e18}();
        address getFunder = fundMeContract.getFunder(0);

        console.log("Funder address: ", funder);
        console.log("Get funder address: ", getFunder);

        assert(getFunder == funder);
    }

    /// @notice Verifies the owner address returned by `getOwner()` equals the deployer (this contract when created in {setUp}).
    /// @dev Read-only assertion.
    function testGetOwner() public view {
        address owner = fundMeContract.getOwner();
        console.log("Owner: ", owner);
        assert(owner == address(this));
    }

    /// @notice End-to-end test for `withdraw()`: two funders deposit, owner withdraws entire balance.
    /// @dev Re-deploys the contract with a custom owner via `vm.prank`, funds with two addresses, and checks post-conditions.
    function testWithdraw() public {
        address owner = address(0xABCD);
        address funder_1 = address(1);
        address funder_2 = address(2);

        // Re-deploy so that `owner` becomes the contract owner for this scenario.
        vm.prank(owner);
        // vm.deal(owner, 1e18); // not required unless sending value in constructor
        fundMeContract = new FundMe(networkConfig.priceFeed);
        console.log("Starting balance of contract:", address(fundMeContract).balance);

        // Funder 1
        vm.prank(funder_1);
        vm.deal(funder_1, 10e18);
        fundMeContract.fund{value: 10e18}();
        console.log("Created funder 1 with address:", funder_1);
        console.log("Funder 1 funded with 10 ETH");
        console.log("Balance of contract after funder 1:", address(fundMeContract).balance);

        // Funder 2
        vm.prank(funder_2);
        vm.deal(funder_2, 10e18);
        fundMeContract.fund{value: 10e18}();
        console.log("Created funder 2 with address:", funder_2);
        console.log("Funder 2 funded with 10 ETH");
        console.log("Balance of contract after funder 2:", address(fundMeContract).balance);

        uint256 startingOwnerBalance = fundMeContract.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMeContract).balance;

        // Owner withdraws
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

    /// @notice End-to-end test for `cheaperWithdraw()`: two funders deposit, owner withdraws entire balance using the gas-optimized path.
    /// @dev Mirrors {testWithdraw} but calls `cheaperWithdraw()` instead of `withdraw()`.
    function testCheaperWithdraw() public {
        address owner = address(0xABCD);
        address funder_1 = address(1);
        address funder_2 = address(2);

        // Re-deploy so that `owner` becomes the contract owner for this scenario.
        vm.prank(owner);
        // vm.deal(owner, 1e18); // not required unless sending value in constructor
        fundMeContract = new FundMe(networkConfig.priceFeed);
        console.log("Starting balance of contract:", address(fundMeContract).balance);

        // Funder 1
        vm.prank(funder_1);
        vm.deal(funder_1, 10e18);
        fundMeContract.fund{value: 10e18}();
        console.log("Created funder 1 with address:", funder_1);
        console.log("Funder 1 funded with 10 ETH");
        console.log("Balance of contract after funder 1:", address(fundMeContract).balance);

        // Funder 2
        vm.prank(funder_2);
        vm.deal(funder_2, 10e18);
        fundMeContract.fund{value: 10e18}();
        console.log("Created funder 2 with address:", funder_2);
        console.log("Funder 2 funded with 10 ETH");
        console.log("Balance of contract after funder 2:", address(fundMeContract).balance);

        uint256 startingOwnerBalance = fundMeContract.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMeContract).balance;

        // Owner withdraws (cheaper)
        vm.prank(fundMeContract.getOwner());
        fundMeContract.cheaperWithdraw();
        console.log("Owner withdrew funds");
        console.log("Balance of contract after withdraw:", address(fundMeContract).balance);
        console.log("Owner balance after withdraw:", fundMeContract.getOwner().balance);

        uint256 endingOwnerBalance = fundMeContract.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMeContract).balance;

        assert(endingFundMeBalance == 0);
        assert(endingOwnerBalance == startingOwnerBalance + startingFundMeBalance);
    }
}
