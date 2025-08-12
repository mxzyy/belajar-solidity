// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Counter.sol";

contract OwnerCounterTest is Test {
    OwnerCounter private oc; // instance yang diuji
    address private owner; // msg.sender saat deploy
    address private bob; // alamat non-owner

    /* ─── Set-up: deploy kontrak, siapkan akun ─── */
    function setUp() public {
        owner = address(this); // Test contract = deployer = owner
        bob = vm.addr(1); // akun lain
        oc = new OwnerCounter(); // deploy; owner = msg.sender (di sini: test)
    }

    /* 1. Nilai awal = 0 */
    function testInitialValueZero() public view {
        assertEq(oc.current(), 0);
    }

    /* 2. Owner boleh increment */
    function testOwnerIncrement() public {
        oc.increment(); // msg.sender = owner
        oc.increment();
        assertEq(oc.current(), 2);
    }

    /* 3. Non-owner tidak boleh increment */
    function testNonOwnerCannotIncrement() public {
        // ubah msg.sender menjadi bob
        vm.prank(bob);
        vm.expectRevert("not owner");
        oc.increment();
    }

    /* 4. Pastikan owner bertahan immutable */
    function testOwnerImmutable() public view {
        assertEq(oc.owner(), owner);
    }
}
