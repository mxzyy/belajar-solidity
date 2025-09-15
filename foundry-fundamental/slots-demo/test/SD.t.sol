// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/SD.sol";

contract SlotsDebugTest is Test {
    SlotsDebug d;
    address A = address(0xBEEF);

    function setUp() public {
        d = new SlotsDebug();
        d.seed(A);
    }

    function testDebugAll() public view {
        // Ini akan nge-print semua info (p, alasan, keccak head/base, dan nilai)
        d.debugAll(A);
    }
}
