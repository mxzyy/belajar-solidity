// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IfElse} from "../src/IfElse.sol";

contract IfElseTest is Test {
    IfElse public ifElse_contract;

    function setUp() public {
        ifElse_contract = new IfElse();
    }

    function test_setNumber() public {
        ifElse_contract.setNumber(2);
        assertEq(ifElse_contract.getNumber(), 2);
    }

    function test_isEven() public {
        ifElse_contract.setNumber(4);
        assertEq(ifElse_contract.isOdd(), false);
    }
}
