// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Encoder {
    function encode(address _address, uint _number) public pure returns (bytes memory) {
        return abi.encode(_address, _number);
    }
}

contract Decoder {
    function decode(bytes memory _data) public pure returns (address _address, uint _number) {
        (_address, _number) = abi.decode(_data, (address, uint));
    }
}