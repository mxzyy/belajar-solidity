// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SIV.sol"; // berisi SIV_Base dan SIV_Child

contract SIVTest is Test {
    SIV_Child private child;
    address private owner; // = address(this)
    address private bob; // non-owner

    // re-declare event agar vm.expectEmit bisa mencocokkan signature
    event VarChanged(address indexed by, string oldValue, string newValue);

    function setUp() public {
        owner = address(this);
        bob = vm.addr(1);

        child = new SIV_Child(); // constructor SIV_Base("Changed in child")
    }

    /// 1) Nilai awal dari child constructor harus "Changed in child"
    function testInitialValueFromChildConstructor() public view {
        assertEq(child.value(), "Changed in child");
        assertEq(child.owner(), owner);
    }

    /// 2) Hanya owner yang boleh setValue()
    function testSetValueByOwner_EmitsEventAndUpdates() public {
        // siapkan ekspektasi event: topic[1] (indexed `by`) dicek, data dicek
        vm.expectEmit(true, false, false, true);
        emit VarChanged(owner, "Changed in child", "Hello");

        child.setValue("Hello");
        assertEq(child.value(), "Hello");
    }

    function testSetValueByNotOwnerReverts() public {
        vm.prank(bob);
        vm.expectRevert(SIV_Base.NotOwner.selector);
        child.setValue("Nope");
    }

    /// 3) Validasi TooLong (>256 byte) harus revert
    function testSetValueTooLongReverts() public {
        // string dengan panjang 257 byte (otomatis null-bytes)
        string memory longStr = new string(257);

        vm.expectRevert(SIV_Base.TooLong.selector);
        child.setValue(longStr);
    }

    /// 4) Override getter di child: value() mengembalikan storage _var milik base
    function testGetterOverrideReadsBaseStorage() public {
        // ubah nilai lalu pastikan getter child mengikuti
        child.setValue("XYZ");
        assertEq(child.value(), "XYZ");
    }
}
