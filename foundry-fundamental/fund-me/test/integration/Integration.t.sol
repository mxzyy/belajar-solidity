// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {FundMe_Fund_InteractionContract, FundMe_Withdraw_InteractionContract} from "../../script/Interaction.s.sol";
import {FundMe} from "../../src/FundMe.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract InteractionTests is ZkSyncChainChecker, StdCheats, Test {
    FundMe public fundme;
    HelperConfig public helperConfig;

    // @notice constants
    uint256 public constant SEND_VALUE = 0.1 ether;
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    address public constant GAS_PRICE = address(1);

    address public USER = address(1);

    function setUp() external skipZkSync {
        if (!isZkSyncChain()) {
            // different deploy script for non-zksync chains
            DeployFundMe deployer = new DeployFundMe();
            (fundme, helperConfig) = deployer.run();
        } else {
            helperConfig = new HelperConfig();
            fundme = new FundMe(helperConfig.getConfigByChainId(block.chainid).priceFeed);
        }

        vm.deal(USER, STARTING_USER_BALANCE);
    }

    function testUserCanFundAndWithdraw() public skipZkSync {
        uint256 preUserBalance = address(USER).balance;
        uint256 preOwnerBalance = address(fundme.getOwner()).balance;
        uint256 originalFundMeBalance = address(fundme).balance;

        console.log("Owner :", address(fundme.getOwner()));
        console.log("FundMe :", address(fundme));

        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();

        FundMe_Withdraw_InteractionContract withdrawer = new FundMe_Withdraw_InteractionContract();
        withdrawer.FundMe_Withdraw_Interaction(address(fundme)); // fundme CA

        uint256 afterUserBalance = address(USER).balance;
        uint256 afterOwnerBalance = address(fundme.getOwner()).balance;

        assert(address(fundme).balance == 0);
        assertEq(afterUserBalance + SEND_VALUE, preUserBalance);
        assertEq(preOwnerBalance + SEND_VALUE + originalFundMeBalance, afterOwnerBalance);
    }
}
