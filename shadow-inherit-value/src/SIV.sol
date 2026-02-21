// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/**
 * GPT EDITED :v
 * Catatan penting tentang "Shadowing Inherited State Variables":
 * --------------------------------------------------------------
 * - Di Solidity modern, Anda TIDAK boleh mendeklarasikan ulang variabel state
 *   dengan nama yang sama di kontrak turunan (child). Itu disebut "shadowing"
 *   dan akan DITOLAK compiler.
 *   Contoh yang dilarang (JANGAN lakukan):
 *
 *     contract Child is Base {
 *         string public _var; // ❌ ERROR: Declaration of '_var' shadows inherited state variable
 *     }
 *
 * - Pola yang benar:
 *   1) Simpan variabelnya di base (mis. `internal _var`) dan
 *   2) Jika perilaku akses ingin dibedakan, OVERRIDE-lah GETTER-nya (fungsi),
 *      BUKAN variabelnya. Atau isi nilainya via constructor base.
 */
contract SIV_Base {
    // ────────────────── Errors & Events ──────────────────
    error NotOwner();
    error TooLong();

    event VarChanged(address indexed by, string oldValue, string newValue);

    // Owner dikunci saat deploy; tidak perlu "shadow" di child.
    address public immutable owner;

    // Simpan nilai utama di BASE. "internal" agar child bisa MEMAKAI,
    // tetapi TIDAK MENDeklarasikan ulang variabel yang sama.
    string internal _var;

    // Injeksi nilai awal via constructor base → pola aman & audit-friendly.
    constructor(string memory initial) {
        owner = msg.sender;
        _set(initial);
    }

    // GETTER "virtual" supaya child bisa override CARA expose value
    // (jika perlu)—ini pengganti "shadowing variabel".
    function value() public view virtual returns (string memory) {
        return _var;
    }

    // Setter dengan kontrol akses; lagi-lagi, child tidak perlu "shadow" state,
    // cukup override fungsi kalau ingin menambah aturan.
    function setValue(string calldata newVal) external virtual {
        if (msg.sender != owner) revert NotOwner();
        _set(newVal);
    }

    // Helper internal untuk validasi + emisi event perubahan.
    function _set(string memory newVal) internal {
        if (bytes(newVal).length > 256) revert TooLong(); // contoh guard
        string memory old = _var;
        _var = newVal;
        emit VarChanged(msg.sender, old, newVal);
    }
}

contract SIV_Child is SIV_Base {
    // POLA BENAR: isi nilai awal dengan memanggil constructor BASE.
    // Tidak ada state baru bernama sama; TIDAK ada "shadowing".
    constructor() SIV_Base("Changed in child") {}

    // Jika ingin perilaku "berbeda" saat membaca nilai, override-lah GETTER,
    // BUKAN mendeklarasikan ulang variabel. Ini aman & sesuai bahasa.
    function value() public view override returns (string memory) {
        // Bisa juga menambahkan dekorasi, logging, dsb.
        return _var;
        // contoh: return string.concat(_var, " (via child)");
    }

    // ❌ CONTOH YANG DILARANG (hanya ilustrasi, jangan dibuka komentarnya):
    //
    // string internal _var; // ← ini akan GAGAL compile: shadowing variabel base
    //
    // ✅ Jika butuh state tambahan di child, pakailah NAMA BERBEDA:
    // string internal childNote;
}
