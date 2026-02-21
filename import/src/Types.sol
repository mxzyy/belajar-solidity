// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Struct yang bisa dipakai lintas kontrak
struct User {
    address account;
    uint256 balance;
}

/// @notice Enum untuk status transaksi
enum Status {
    Pending,
    Success,
    Failed
}

/// @notice Custom error untuk gas efficient reverts
error NotAuthorized(address caller);
