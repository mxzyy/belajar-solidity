// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Variables} from "../src/Variables.sol";

contract VariablesTest is Test {
    Variables public variables;

    function setUp() public {
        variables = new Variables();
    }

    function test_SetNum() public {
        variables.setSomethingNum(3);
        assertEq(variables.getNum(), 3);
    }

    function test_SetStr() public {
        variables.setSomethingText("awawa");
        assertEq(variables.getStr(), "awawa");
    }

    // function testFuzz_SetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }
}
