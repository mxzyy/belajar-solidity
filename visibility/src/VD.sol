// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VisibilityDemo {
    uint256 public counter; // contoh state + auto-getter counter()

    /* ─────────────────────────────
       PUBLIC: bisa dipanggil dari luar & dalam kontrak
       ───────────────────────────── */
    function inc() public returns (uint256) {
        counter += 1;
        return counter;
    }

    /* ─────────────────────────────
       EXTERNAL: hanya dari luar kontrak.
       Dari dalam kontrak, HARUS via `this.fn()` (message call, lebih mahal gas).
       ───────────────────────────── */
    function double(uint256 x) external pure returns (uint256) {
        return x * 2;
    }

    // wrapper untuk memanggil external dari dalam kontrak
    function callExternal(uint256 x) public view returns (uint256) {
        // Note: ini melakukan CALL ke alamat kontrak sendiri (lebih mahal)
        return this.double(x);
    }

    /* ─────────────────────────────
       INTERNAL: hanya kontrak ini & turunan yang bisa panggil.
       Tidak bisa dari luar.
       ───────────────────────────── */
    function _sum(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    // wrapper agar bisa dites dari luar
    function useInternal(uint256 a, uint256 b) public pure returns (uint256) {
        return _sum(a, b);
    }

    /* ─────────────────────────────
       PRIVATE: hanya kontrak ini sendiri yang bisa panggil.
       Anak/turunan pun TIDAK bisa mengakses.
       ───────────────────────────── */
    function _times3(uint256 x) private pure returns (uint256) {
        return x * 3;
    }

    // wrapper agar efek private bisa terlihat dari luar
    function usePrivate(uint256 x) public pure returns (uint256) {
        return _times3(x);
    }
}
