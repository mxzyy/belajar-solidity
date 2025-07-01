// test/CounterTest.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/FirstApplication.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
        console.log("Counter deployed at:", address(counter));
        console.log("Initial count:", counter.get());
    }

    function test_Increment() public {
        uint256 prev = counter.get();
        counter.inc();
        assertEq(counter.get(), prev + 1);
    }

    function test_Decrement() public {
        uint256 prev = counter.get();
        counter.inc();
        counter.dec();
        assertEq(counter.get(), prev);
    }
}
