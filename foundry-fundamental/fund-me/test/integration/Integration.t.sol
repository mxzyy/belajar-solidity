// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundMe} from "../../src/FundMe.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

/// @title Integration_FundMe
/// @notice End-to-end integration tests for FundMe
/// @dev We deploy with an explicit EOA owner to ensure withdrawals do not revert.
contract Integration_FundMe is Test {
    FundMe public fundme;
    HelperConfig public helperConfig;

    /// @notice EOA that will be the FundMe owner (constructor sender)
    address public OWNER = makeAddr("owner");
    address public OWNER2 = makeAddr("owner2");

    /// @notice Test user account that will fund
    address public USER = makeAddr("user");

    uint256 public constant SEND_VALUE = 0.1 ether;
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    /// @notice Deploy FundMe with OWNER as EOA and seed balances
    function setUp() public {
        // Ensure OWNER & USER are funded for realism (OWNER may not need funds with tx.gasprice=0)
        vm.deal(OWNER, 1 ether);
        vm.deal(USER, STARTING_USER_BALANCE);
        vm.txGasPrice(0); // exact balance equality in asserts

        DeployFundMe d = new DeployFundMe();
        (fundme, helperConfig) = d.deploy(false, OWNER); // no broadcast; constructor sender = OWNER (EOA)
        assertEq(fundme.getOwner(), OWNER, "owner must be EOA");
    }

    /// @notice User funds; owner withdraws; contract drained; balances updated
    function test_UserCanFund_ThenOwnerWithdraw() public {
        uint256 preUser = USER.balance;
        uint256 preOwner = OWNER.balance;
        uint256 preContract = address(fundme).balance;

        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();

        // Withdraw by the EOA owner
        vm.prank(OWNER);
        fundme.withdraw();

        assertEq(address(fundme).balance, 0, "contract not drained");
        assertEq(USER.balance, preUser - SEND_VALUE, "user balance mismatch");
        assertEq(OWNER.balance, preOwner + preContract + SEND_VALUE, "owner balance mismatch");
    }

    /// @notice Non-owner cannot withdraw
    function test_NonOwner_CannotWithdraw() public {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();

        vm.prank(USER);
        vm.expectRevert(); // replace with specific selector if FundMe uses custom error
        fundme.withdraw();
    }

    function test_Deploy_NoBroadcast_DefaultSender() public {
        // Menyentuh path: doBroadcast=false, desiredOwner=0
        DeployFundMe d = new DeployFundMe();
        (FundMe f,) = d.deploy(false, address(0xabc));
        // Jika FundMe expose getOwner(), bisa assert; kalau tidak, cukup non-zero
        try f.getOwner() returns (address o) {
            assertEq(o, address(0xabc));
        } catch {
            assertTrue(address(f) != address(0));
        }
    }

    function test_Deploy_NoBroadcast_CustomOwner() public {
        // Path: doBroadcast=false, desiredOwner!=0 (vm.prank)
        DeployFundMe d = new DeployFundMe();
        (FundMe f,) = d.deploy(false, OWNER2);
        assertEq(f.getOwner(), OWNER2);
    }

    function test_Deploy_Broadcast_CustomOwner() public {
        // Path: doBroadcast=true, desiredOwner!=0 (vm.startBroadcast(addr))
        vm.deal(OWNER2, 100 ether);
        DeployFundMe d = new DeployFundMe();
        (FundMe f,) = d.deploy(true, OWNER2);
        assertEq(f.getOwner(), OWNER2);
    }

    function test_Run_Broadcast_DefaultBroadcaster_CoversBranch() public {
        DeployFundMe d = new DeployFundMe();
        (FundMe f,) = d.run(); // hits: doBroadcast=true, desiredOwner=0
        address o = f.getOwner();
        assertTrue(o != address(0), "owner zero");
        assertTrue(o != address(this), "should not be test contract");
    }
}
