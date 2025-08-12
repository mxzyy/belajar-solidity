// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* ─────────────────────────  Kontrak dasar  ───────────────────────── */
/**
 * @title Counter
 * @dev Menyediakan penyimpanan angka dan fungsi tambah 1.
 */
contract Counter {
    uint256 internal _value; // angka tersimpan

    /// @notice mengembalikan nilai terkini
    function current() public view returns (uint256) {
        return _value;
    }

    /// @notice menaikkan nilai +1
    function increment() public virtual {
        _value += 1;
    }
}

/* ────────────────────────  Kontrak turunan  ──────────────────────── */
/**
 * @title OwnerCounter
 * @dev Mewarisi Counter dan membatasi increment hanya untuk owner.
 */
contract OwnerCounter is Counter {
    address public immutable owner;

    constructor() {
        owner = msg.sender; // set sekali di deploy
    }

    /// modifier akses sederhana
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    /// override: tambahkan pembatas akses
    function increment() public override onlyOwner {
        super.increment(); // panggil logika asli dari Counter
    }
}
