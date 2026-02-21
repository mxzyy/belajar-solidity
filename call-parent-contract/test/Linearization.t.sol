// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Linearization.sol"; // A, B, C, D

contract LinearizationTest is Test {
    D private d;

    // re-declare event agar expectEmit bisa cocokkan signature
    event Log(string who);

    function setUp() public {
        d = new D();
    }

    /// Benar: urutan event = D → C → B → A
    function test_Order_D_C_B_A() public {
        // Cocokkan emitter (address d) dan data event (string)
        vm.expectEmit(false, false, false, true, address(d));
        emit Log("D");

        vm.expectEmit(false, false, false, true, address(d));
        emit Log("C");

        vm.expectEmit(false, false, false, true, address(d));
        emit Log("B");

        vm.expectEmit(false, false, false, true, address(d));
        emit Log("A");

        d.f();
    }
}
