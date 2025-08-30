// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/TC.sol";

/* ------------------------------------------------------------------------- */
/*                                Mocks                                      */
/* ------------------------------------------------------------------------- */

/// @notice Mock target untuk skenario external call.
/// - x == 0  -> Error(string) via require
/// - x == 1  -> Panic(uint) (division by zero)
/// - else    -> return x + 1
contract MockTarget is ITarget {
    uint256 public lastValue;

    receive() external payable {
        lastValue += msg.value;
    }

    function risky(uint256 x) external payable override returns (uint256) {
        // catat ETH yang dikirim via call{value: ...}()
        lastValue += msg.value;

        if (x == 0) revert("x=0 not allowed"); // -> Error(string)
        if (x == 1) {
            uint256 y = 0;
            // division by zero -> Panic(0x12)
            return 1 / y;
        }
        return x + 1;
    }
}

/* ------------------------------------------------------------------------- */
/*                           Test Suite for TC                               */
/* ------------------------------------------------------------------------- */
contract TCTest is Test {
    /* Re-declare events with identical signatures for expectEmit */
    enum ReasonKind {
        None,
        Error,
        Panic,
        LowLevel
    }

    event OperatorUpdated(address indexed who, bool enabled);

    event ExternalCallSucceeded(address indexed target, bytes4 indexed selector, bytes result);

    event ExternalCallFailed(
        address indexed target,
        bytes4 indexed selector,
        ReasonKind kind,
        string reasonStr,
        uint256 panicCode,
        bytes lowLevelData
    );

    event ChildDeployed(address indexed child, uint256 valueSent);

    event ChildDeployFailed(ReasonKind kind, string reasonStr, uint256 panicCode, bytes lowLevelData);

    TC internal tc;
    MockTarget internal target;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function setUp() public {
        tc = new TC(); // owner = this (test contract)
        target = new MockTarget(); // mock external target

        // seed balances
        vm.deal(address(this), 100 ether);
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
    }

    /* ---------------------------- Ownership / Roles ---------------------------- */

    function test_OwnerCanCall_onlyOperatorGate() public {
        // owner (test contract) boleh call meski belum set operator
        (bool ok,) = tc.safeExternalCall{value: 0}(address(target), 2, bytes4(0x12345678), 0);
        assertTrue(ok, "owner should pass onlyOperator");
    }

    function test_NonOperatorAndNonOwner_Reverts_onlyOperator() public {
        vm.prank(alice); // not owner, not operator
        vm.expectRevert(Unauthorized.selector);
        tc.safeExternalCall(address(target), 2, bytes4(0x0), 0);
    }

    function test_SetOperator_EmitsEvent_AndAllowsCall() public {
        vm.expectEmit(true, false, false, true, address(tc));
        emit OperatorUpdated(bob, true);
        tc.setOperator(bob, true);

        // bob sekarang boleh eksekusi
        vm.prank(bob);
        (bool ok,) = tc.safeExternalCall(address(target), 2, bytes4(0x0), 0);
        assertTrue(ok, "operator should be allowed");
    }

    function test_SetOperator_OnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert(Unauthorized.selector);
        tc.setOperator(bob, true);
    }

    function test_TransferOwnership_Works() public {
        tc.transferOwnership(alice);
        assertEq(tc.owner(), alice);
    }

    /* ------------------------- safeExternalCall: Success ----------------------- */

    function test_safeExternalCall_Success_EmitsAndReturns() public {
        uint256 sendValue = 1 ether;
        bytes4 sel = bytes4(0xC0FFEE00);

        vm.expectEmit(true, true, false, true, address(tc));
        emit ExternalCallSucceeded(address(target), sel, abi.encode(uint256(3))); // x=2 -> 3

        (bool ok, bytes memory out) = tc.safeExternalCall{value: sendValue}(address(target), 2, sel, sendValue);

        assertTrue(ok, "should succeed");
        assertEq(abi.decode(out, (uint256)), 3, "result should be x+1");
        assertEq(target.lastValue(), sendValue, "ETH must be forwarded");
    }

    /* ------------------------ safeExternalCall: Error(string) ------------------ */

    function test_safeExternalCall_Catches_ErrorString() public {
        bytes4 sel = bytes4(0xABCD1234);

        vm.expectEmit(true, true, false, true, address(tc));
        emit ExternalCallFailed(address(target), sel, ReasonKind.Error, "x=0 not allowed", 0, "");

        (bool ok, bytes memory out) = tc.safeExternalCall(
            address(target),
            0, // triggers require -> Error(string)
            sel,
            0
        );

        assertFalse(ok, "should be caught as Error(string)");
        assertEq(out.length, 0, "no payload on failure");
    }

    /* ------------------------ safeExternalCall: Panic(uint) -------------------- */

    function test_safeExternalCall_Catches_Panic() public {
        bytes4 sel = bytes4(0xDEADBEEF);

        // We don't assert exact panic code number here; only that it's Panic branch.
        vm.expectEmit(true, true, false, true, address(tc));
        emit ExternalCallFailed(address(target), sel, ReasonKind.Panic, "", 0x12, "");

        (bool ok,) = tc.safeExternalCall(
            address(target),
            1, // triggers division by zero -> Panic
            sel,
            0
        );

        assertFalse(ok, "should be caught as Panic(uint)");
    }

    /* ------------------------- safeExternalCall: Guards ------------------------ */

    function test_safeExternalCall_RevertsOn_EtherMismatch() public {
        vm.expectRevert(EtherMismatch.selector);
        tc.safeExternalCall{value: 1 wei}(address(target), 2, bytes4(0), 0); // value param != msg.value
    }

    function test_safeExternalCall_RevertsOn_ZeroAddress() public {
        vm.expectRevert(ZeroAddress.selector);
        tc.safeExternalCall(address(0), 2, bytes4(0), 0);
    }

    /* --------------------------- safeExternalSelf ------------------------------ */

    function test_safeExternalSelf_Success() public view {
        (bool ok, uint256 out) = tc.safeExternalSelf(5);
        assertTrue(ok);
        assertEq(out, 100 / 5);
    }

    function test_safeExternalSelf_Catches_Error() public view {
        (bool ok, uint256 out) = tc.safeExternalSelf(0); // require in riskySelf
        assertFalse(ok);
        assertEq(out, 0);
    }

    /* ------------------------------ safeDeployChild ---------------------------- */

    function test_safeDeployChild_Success() public {
        uint256 val = 0.5 ether;

        // Jangan cek topic indexed (alamat child), tapi cek data (valueSent)
        vm.expectEmit(false, false, false, true, address(tc));
        emit ChildDeployed(address(0), val); // address(0) diabaikan karena topic check=false

        (bool ok, address child) = tc.safeDeployChild{value: val}(address(0xBEEF), 7);
        assertTrue(ok, "deploy should succeed");
        assertTrue(child != address(0), "child must be non-zero");
        assertEq(address(child).balance, val, "child received constructor value");
    }

    function test_safeDeployChild_Catches_LowLevel_OnCustomError_ZeroOwner() public {
        // Abaikan data karena lowLevelData tidak kosong dan tidak deterministik
        vm.expectEmit(false, false, false, false, address(tc));
        emit ChildDeployFailed(ReasonKind.LowLevel, "", 0, "");

        (bool ok, address child) = tc.safeDeployChild(address(0), 7);
        assertFalse(ok, "should be caught as LowLevel (custom error)");
        assertEq(child, address(0));
    }

    function test_safeDeployChild_Catches_LowLevel_OnCustomError_BadSeed() public {
        vm.expectEmit(false, false, false, false, address(tc));
        emit ChildDeployFailed(ReasonKind.LowLevel, "", 0, "");

        (bool ok, address child) = tc.safeDeployChild(address(0xBEEF), 0);
        assertFalse(ok, "should be caught as LowLevel (custom error)");
        assertEq(child, address(0));
    }
}
