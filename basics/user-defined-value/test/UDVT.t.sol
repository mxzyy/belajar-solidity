// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/UDVT.sol";

contract UDVTTest is Test {
    UDVT uc;

    function setUp() public {
        vm.warp(1_000_000); // pastikan timestamp deterministik
        uc = new UDVT();
    }

    function testConstructorStoresTimestamp() public view {
        assertEq(uc.createdAt(), 1_000_000);
    }

    function testSetWalletAndGetter() public {
        address alice = address(0xABCD);
        uc.setWallet(alice);
        assertEq(uc.wallet(), alice);
    }

    function testMultipleUpdates() public {
        address a1 = address(0x1);
        address a2 = address(0x2);

        uc.setWallet(a1);
        assertEq(uc.wallet(), a1);

        uc.setWallet(a2);
        assertEq(uc.wallet(), a2);
    }
}
