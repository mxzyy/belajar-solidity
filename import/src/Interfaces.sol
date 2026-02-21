// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Interface standar ERC20 (simplified)
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}
