// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract DL {
    /* -------------------------------------------------------------------------- */
    /*                               1.  STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    // Variabel state otomatis berada di `storage` (persisten di blockchain)
    address public immutable owner;

    constructor() {
        owner = msg.sender; // ✅ alamat deployer disimpan di storage
    }

    /* -------------------------------------------------------------------------- */
    /*                               2.  MEMORY                                   */
    /* -------------------------------------------------------------------------- */
    // `memory` dipakai untuk data sementara yang bisa diubah selama eksekusi.
    function memoryFunction(string memory _name)
        external
        pure
        returns (
            string memory // hasil juga di memory
        )
    {
        string memory name = _name; // salin ke memory (tidak wajib, hanya contoh)
        return name; // kembalikan data di memory
    }

    /* -------------------------------------------------------------------------- */
    /*                               3.  CALLDATA                                 */
    /* -------------------------------------------------------------------------- */
    // `calldata` = area read-only input transaksi; hemat gas & tidak bisa diubah.
    // Hanya berlaku untuk *reference types* (array, bytes, string, struct).
    // Contoh: penjumlahan batch dari dua array uint256 di calldata.
    function sumCalldata(uint256[] calldata a, uint256[] calldata b) external pure returns (uint256[] memory sums) {
        require(a.length == b.length, "Length mismatch");
        sums = new uint256[](a.length); // hasil disimpan di memory (bisa diubah)

        for (uint256 i = 0; i < a.length; ++i) {
            sums[i] = a[i] + b[i]; // baca langsung dari calldata (hemat gas)
        }
        return sums;
    }

    /* -------------------------------------------------------------------------- */
    /*                     4.  NILAI KEMBALI SEDERHANA (PURE)                     */
    /* -------------------------------------------------------------------------- */
    // Contoh fungsi `pure` sederhana tanpa akses state:
    function add(uint256 x, uint256 y) external pure returns (uint256) {
        return x + y;
    }
}
