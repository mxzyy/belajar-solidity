// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Events.sol";

contract EventsTest is Test {
    Events private ev;

    function setUp() public {
        ev = new Events();
    }

    event Called(address indexed caller, string funcName);

    function testEmitCalled() public {
        /* 1️⃣  Siapkan ekspektasi event */
        vm.expectEmit(true, false, false, true, address(ev)); // topic[1]=indexed caller harus cocok
        emit Called(address(this), "callFunction");

        /* 2️⃣  Panggil fungsi yang diuji */
        string memory ret = ev.callFunction();

        /* 3️⃣  Pastikan nilai balik juga benar (opsional) */
        assertEq(ret, "Function Called");
    }
}
