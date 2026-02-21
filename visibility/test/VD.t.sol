// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VD.sol"; // <-- sesuaikan path

contract VisibilityDemoTest is Test {
    VisibilityDemo private demo;

    function setUp() public {
        demo = new VisibilityDemo();
    }

    /* ────────────────────────────────────────────────────────────────
       PUBLIC: bisa dipanggil dari luar & dalam, ada efek ke state
       ──────────────────────────────────────────────────────────────── */
    function testPublic_incIncrementsCounter() public {
        assertEq(demo.counter(), 0);
        uint256 r1 = demo.inc();
        uint256 r2 = demo.inc();

        assertEq(r1, 1);
        assertEq(r2, 2);
        assertEq(demo.counter(), 2); // getter auto dari `public counter`
    }

    /* ────────────────────────────────────────────────────────────────
       EXTERNAL: harus dipanggil dari luar kontrak
       (dari test contract ini dianggap “luar”)
       ──────────────────────────────────────────────────────────────── */
    function testExternal_doubleFromOutside() public view {
        uint256 out = demo.double(7); // ok: kita kontrak lain
        assertEq(out, 14);
    }

    /* ────────────────────────────────────────────────────────────────
       Memanggil EXTERNAL dari DALAM kontrak → wajib via `this.fn()`
       Kita uji lewat wrapper callExternal()
       ──────────────────────────────────────────────────────────────── */
    function testExternal_calledInternallyViaThis() public view {
        uint256 out = demo.callExternal(8); // internal call → this.double(8)
        assertEq(out, 16);
    }

    /* ────────────────────────────────────────────────────────────────
       INTERNAL: tidak bisa dipanggil dari luar; uji via wrapper public
       ──────────────────────────────────────────────────────────────── */
    function testInternal_sumThroughWrapper() public pure {
        // PANGGIL wrapper static (pure) saja via instance tak bisa,
        // jadi kita buat instance lokal berbasis interface? Tidak perlu.
        // Di sini cukup verifikasi perilaku wrapper pada instance langsung.
        // Note: fungsi useInternal di kontrak tidak pure, tapi kita panggil
        // di instance demo (bukan staticcall).
    }

    function testInternal_sumThroughWrapperStateful() public view {
        uint256 s = demo.useInternal(2, 3);
        assertEq(s, 5);
    }

    /* ────────────────────────────────────────────────────────────────
       PRIVATE: juga tidak bisa dipanggil dari luar; uji via wrapper public
       ──────────────────────────────────────────────────────────────── */
    function testPrivate_times3ThroughWrapper() public view {
        uint256 s = demo.usePrivate(4);
        assertEq(s, 12);
    }
}
