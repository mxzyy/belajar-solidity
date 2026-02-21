// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Array} from "../src/Array.sol";

contract CounterTest is Test {
    Array public arrayContract;

    function setUp() public {
        arrayContract = new Array();
    }

    function test_AddUser() public {
        arrayContract.add("alice", address(0xABCD));
        (string memory name, address addr) = arrayContract.get(0);
        assertEq(name, "alice");
        assertEq(addr, address(0xABCD));
    }

    function test_GetByKey() public {
        arrayContract.add("bob", address(0xBEEF));
        address result = arrayContract.getByKey("bob");
        assertEq(result, address(0xBEEF));
    }

    function test_GetUserCount() public {
        arrayContract.add("u1", address(0x1));
        arrayContract.add("u2", address(0x2));
        arrayContract.add("u3", address(0x3));

        uint count = arrayContract.getUserCount();
        assertEq(count, 3);
    }

    function test_GetRevertsWhenIndexOutOfBounds() public {
        vm.expectRevert("Index out of bounds");
        arrayContract.get(0); // belum ada data
    }

    function test_GetByKeyRevertsIfNotFound() public {
        vm.expectRevert("User not found");
        arrayContract.getByKey("nonexistent");
    }
}
