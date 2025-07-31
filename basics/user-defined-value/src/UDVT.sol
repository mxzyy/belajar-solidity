// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/* ---------- 1. User-defined value types ---------- */
type Timestamp is uint256;

type Wallet is address; // Owner ditiadakan (string tak bisa di-wrap)

type Nickname is bytes32; // Contoh wrap text pendek (opsional)

/* ---------- 2. Library helper  ---------- */
library Helper {
    /* waktu sekarang dibungkus ke UDVT */
    function nowTs() internal view returns (Timestamp) {
        return Timestamp.wrap(block.timestamp);
    }

    /* konversi Wallet → address (unwrap) */
    function addr(Wallet w) internal pure returns (address) {
        return Wallet.unwrap(w);
    }
}

/* ---------- 3. Contract utama ---------- */
contract UDVT {
    using Helper for Wallet;

    Wallet private _wallet;
    Timestamp private _created;

    constructor() {
        _created = Helper.nowTs();
    }

    /* -------- Mutator -------- */
    function setWallet(address a) external {
        _wallet = Wallet.wrap(a);
    }

    /* -------- View -------- */
    function wallet() external view returns (address) {
        return _wallet.addr(); // pakai ekstensi helper
    }

    function createdAt() external view returns (uint256) {
        return Timestamp.unwrap(_created);
    }
}
