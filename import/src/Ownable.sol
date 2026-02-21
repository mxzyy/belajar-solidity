// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Simple Ownable (contoh reusable contract)
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    error NotOwner();

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero addr");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
