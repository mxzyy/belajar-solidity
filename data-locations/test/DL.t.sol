// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/DL.sol"; // ubah path jika kontrak ada di folder lain

contract DLTest is Test {
    DL private dl;

    function setUp() public {
        dl = new DL(); // deploy; msg.sender = address(this)
    }

    /* ---------- 1. owner terset di storage ---------- */
    function testOwnerIsDeployer() public view {
        assertEq(dl.owner(), address(this));
    }

    /* ---------- 2. memoryFunction meng-echo string ---------- */
    function testMemoryFunction() public view {
        string memory input = "alice";
        string memory output = dl.memoryFunction(input);
        assertEq(output, input);
    }

    /* ---------- 3. sumCalldata penjumlahan dua array ---------- */
    function testSumCalldata() public {
        /* ---------------------------------------------------------- */
        /* 1.  ALLOKASI — wajib NEW, barulah array punya panjang      */
        /* ---------------------------------------------------------- */
        uint256[] memory a = new uint256[](3);
        uint256[] memory b = new uint256[](3);
        /* 2.  ISI ELEMEN                                             */
        a[0] = 1;
        a[1] = 2;
        a[2] = 3;

        b[0] = 4;
        b[1] = 5;
        b[2] = 6;

        /* 3.  PANGGIL FUNGSI YANG DIUJI                              */
        uint256[] memory sums = dl.sumCalldata(a, b);

        /* 4.  VERIFIKASI                                             */
        uint256[3] memory expected = [uint256(5), 7, 9];
        for (uint256 i = 0; i < expected.length; ++i) {
            assertEq(sums[i], expected[i]);
        }
    }

    /* ---------- 4. add() murni ---------- */
    function testAddPure() public view {
        assertEq(dl.add(7, 11), 18);
    }
}
