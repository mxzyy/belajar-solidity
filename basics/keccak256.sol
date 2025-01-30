// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract keccakHash {
    function HashString(string memory _data) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_data));
    }

    function HashNumber(uint _data) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_data));
    }

    function HashAddy(address _data) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_data));
    }

    function HashAllofThem(string memory _str, uint _uint, address _address) public pure  returns (bytes32) {
        return keccak256(abi.encodePacked(_str, _uint, _address));
    }
}