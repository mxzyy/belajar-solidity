// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {fixedVariable} from "../src/fixedVariable.sol";

contract fixedVariableTest is Test {
    fixedVariable public fixedVar;

    function setUp() public {
        fixedVar = new fixedVariable();
    }

    // function test_Increment() public {
    //     counter.increment();
    //     assertEq(counter.number(), 1);
    // }

    // function testFuzz_SetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }
}
