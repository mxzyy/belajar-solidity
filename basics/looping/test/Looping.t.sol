// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Looping} from "../src/Looping.sol";

contract CounterTest is Test {
    Looping public looping;

    function setUp() public {
        looping = new Looping();
    }

    function test_forLoop() public view {
        uint256 res = looping.for_loop();
        assertEq(res, 10);
    }

    function test_whileLoop() public view {
        uint256 res = looping.while_loop();
        assertEq(res, 10);
    }

    function test_doWhileLoop() public view {
        uint256 res = looping.do_while();
        assertEq(res, 10);
    }
}
