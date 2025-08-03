// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28; // sama dgn kontrak (atau ganti 0.8.24 jika pakai opsi B)

import "forge-std/Test.sol";
import "../src/TStore.sol"; // sesuaikan path

contract TStoreTest is Test {
    TStore private t;

    function setUp() public {
        t = new TStore();
    }

    function testSetAndGet() public {
        t.setNumber(42);
        assertEq(t.getNumber(), 42);
    }

    // Pastikan transient ter-reset antar transaksi
    function testWriteTransient() public {
        t.setNumber(99);
        assertEq(t.getNumber(), 99); // masih tx yang sama ⇒ 99
    }

    function testReadAfterReset() public {
        // tidak men-set apa-apa ⇒ transaksi baru, slot sudah 0
        assertEq(t.getNumber(), 0); // ✅ reset berhasil
    }
}
