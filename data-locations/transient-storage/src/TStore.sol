// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24; // EIP-1153

contract TStore {
    uint256 transient myNumber;

    function setNumber(uint256 _number) external {
        myNumber = _number;
    }

    function getNumber() public view returns (uint256) {
        return myNumber;
    }
}
