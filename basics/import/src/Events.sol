// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Tempat deklarasi event global
abstract contract Events {
    event UserRegistered(address indexed user, uint256 timestamp);
}
