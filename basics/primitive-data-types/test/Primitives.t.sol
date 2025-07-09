// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Primitives} from "../src/Primitives.sol";

contract CounterTest is Test {
    Primitives public primitives;

    function setUp() public {
        primitives = new Primitives();
    }

    function test_checkBool() public view {
        bool varBool = primitives.boo();
        assertEq(varBool, true);
    }

    function test_check_u8() public view {
        uint8 u8 = primitives.u8();
        assertEq(u8, 1);
    }

    function test_check_u256() public view {
        uint256 u256 = primitives.u256();
        assertEq(u256, 456);
    }

    function test_check_u() public view {
        uint256 u = primitives.u();
        assertEq(u, 123);
    }

    function test_check_i8() public view {
        int8 i8 = primitives.i8();
        assertEq(i8, -1);
    }

    function test_check_i256() public view {
        int256 i256 = primitives.i256();
        assertEq(i256, 456);
    }

    function test_check_i() public view {
        int256 i = primitives.i();
        assertEq(i, -123);
    }

    function test_check_minInt() public view {
        int256 minInt = primitives.minInt();
        assertEq(minInt, type(int256).min);
    }

    function test_check_maxInt() public view {
        int256 maxInt = primitives.maxInt();
        assertEq(maxInt, type(int256).max);
    }

    function test_check_addr() public view {
        address addr = primitives.addr();
        assertEq(addr, 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c);
    }

    function test_check_bytes1() public view {
        bytes1 aBytes = primitives.a();
        bytes1 expectedA = 0xb5;
        assertEq(aBytes, expectedA);
    }

    function test_check_bytes2() public view {
        bytes1 bBytes = primitives.b();
        bytes1 expectedB = 0x56;
        assertEq(bBytes, expectedB);
    }

    function test_check_defaultBoo() public view {
        bool defaultBoo = primitives.defaultBoo();
        assertEq(defaultBoo, false);
    }

    function test_check_defaultUint() public view {
        uint256 defaultUint = primitives.defaultUint();
        assertEq(defaultUint, 0);
    }

    function test_check_defaultInt() public view {
        int256 defaultInt = primitives.defaultInt();
        assertEq(defaultInt, 0);
    }
    
    function test_check_defaultAddr() public view {
        address defaultAddr = primitives.defaultAddr();
        assertEq(defaultAddr, 0x0000000000000000000000000000000000000000);
    }
}
