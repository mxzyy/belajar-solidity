// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {FundSubscriptionLib, FundLogic} from "../../src/RaffleInteractionLib.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract FundSubscriptionLibHarness {
    function callPrepareFundParams(HelperConfig.NetworkConfig memory cfg)
        external
        pure
        returns (FundSubscriptionLib.FundParams memory)
    {
        return FundSubscriptionLib.prepareFundParams(cfg);
    }
}

contract FundSubscriptionLibTest is Test {
    HelperConfig helper;
    FundSubscriptionLibHarness harness;

    function setUp() public {
        helper = new HelperConfig();
        harness = new FundSubscriptionLibHarness();
        // set config sesuai scenario test
    }

    function testPrepareFundParams_UsesExistingSubscription() public {
        // arrange
        HelperConfig.NetworkConfig memory cfg = helper.getOrCreateAnvilEthConfig();
        // misal lu save manual ke mapping chain tertentu

        FundSubscriptionLib.FundParams memory p = FundSubscriptionLib.prepareFundParams(cfg);

        assertEq(p.subId, cfg.subscriptionId);
        assertEq(p.vrfCoordinatorV2_5, cfg.vrfCoordinatorV2_5);
    }

    function testPrepareFundParamsSubscriptionZeroReverts() public {
        // Ambil config dulu (boleh dari helper, terserah)
        HelperConfig.NetworkConfig memory cfg = helper.getOrCreateAnvilEthConfig();
        cfg.subscriptionId = 0; // force zero

        vm.expectRevert(bytes("TODO: handle create sub di sini atau di luar"));

        // PENTING: ADA CALL SETELAH EXPECTREVERT
        harness.callPrepareFundParams(cfg);
    }

    function testPrepareFundParamsHappyPath() public {
        HelperConfig.NetworkConfig memory cfg = helper.getOrCreateAnvilEthConfig();
        // Pastikan subId != 0
        assertTrue(cfg.subscriptionId != 0);

        FundSubscriptionLib.FundParams memory params = harness.callPrepareFundParams(cfg);

        assertEq(params.subId, cfg.subscriptionId);
        assertEq(params.vrfCoordinatorV2_5, cfg.vrfCoordinatorV2_5);
        assertEq(params.link, cfg.link);
        assertEq(params.account, cfg.account);
    }

    function testLocalCheck() public pure {
        // arrange
        uint256 localChainId = 31337;
        uint256 otherChainId = 1;

        // act & assert
        assertTrue(FundLogic.isLocal(localChainId, localChainId));
        assertFalse(FundLogic.isLocal(otherChainId, localChainId));
    }
}
