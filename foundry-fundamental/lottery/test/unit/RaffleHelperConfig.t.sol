// SPDX-License-Identifier: UNCLICENSED
pragma solidity ^0.8.20;

import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

contract RaffleLibraryTest is Test {
    /*//////////////////////////////////////////////////////////////
                                 ErrORS
    //////////////////////////////////////////////////////////////*/
    error HelperConfig__InvalidChainId();

    /*//////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    HelperConfig public helper;

    /*//////////////////////////////////////////////////////////////
                               SETUP
    //////////////////////////////////////////////////////////////*/
    function setUp() external {
        helper = new HelperConfig();
    }

    /*//////////////////////////////////////////////////////////////
                             TEST FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function testSetConfigStoresNetworkConfig() public {
        HelperConfig.NetworkConfig memory cfg;
        cfg.subscriptionId = 123;
        cfg.gasLane = bytes32("abc");
        cfg.account = address(0xdeadbeef);
        cfg.vrfCoordinatorV2_5 = address(0x12345678);

        helper.setConfig(1337, cfg); // Sepolia chain ID

        HelperConfig.NetworkConfig memory updatedConfig = helper.getConfigByChainId(1337);

        assertEq(updatedConfig.subscriptionId, 123);
        assertEq(updatedConfig.gasLane, bytes32("abc"));
        assertEq(updatedConfig.account, address(0xdeadbeef));
        assertEq(updatedConfig.vrfCoordinatorV2_5, address(0x12345678));
    }

    function testGetConfigByChainIdReturnManualConfig() public {
        HelperConfig.NetworkConfig memory cfg;

        cfg.vrfCoordinatorV2_5 = address(0); // #1 Flag to identify our manual config
        cfg.subscriptionId = 456;
        cfg.account = address(0xcafebabe);
        helper.setConfig(42, cfg); // Manual chain ID

        vm.expectRevert(HelperConfig__InvalidChainId.selector);
        helper.getConfigByChainId(42);
    }

    function testGetOrCreateAnvilEthConfigCreatesWhenNotExists() public {
        HelperConfig.NetworkConfig memory cfg = helper.getOrCreateAnvilEthConfig();

        assertTrue(cfg.vrfCoordinatorV2_5 != address(0), "VRFCoordinatorV2_5 address should not be zero");
        assertTrue(cfg.subscriptionId != 0, "Subscription ID should not be zero");
        assertTrue(cfg.link != address(0), "Link token address should not be zero");
        assertEq(cfg.automationUpdateInterval, 30, "Automation update interval should be 30");
        assertEq(cfg.raffleEntranceFee, 0.01 ether, "Raffle entrance fee should be 0.01 ether");
        assertEq(cfg.callbackGasLimit, 500000, "Callback gas limit should be 500000");
    }
}
