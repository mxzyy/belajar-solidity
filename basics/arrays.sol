// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

contract Array {
    struct simpleLedger {
        string owner;
        address public_key;
    }

    simpleLedger[] public array;

    function addData(string memory _owner, address  _pubkey) public {
       array.push( simpleLedger(_owner, _pubkey) );

    }
    function getPubkey(string memory _owner) public view returns (address) {
        for (uint256 i = 0; i < array.length; i++) {
            if (keccak256(abi.encodePacked(array[i].owner)) == keccak256(abi.encodePacked(_owner))) {
                return array[i].public_key;
            }
        }
        // if not found
        return address(0);
    }

    function getOwner(address _pubkey) public view returns (string memory owner) {
        for (uint256 i = 0; i < array.length; i++) {
            if ((array[i].public_key) == _pubkey) {
                return array[i].owner;
            }
        }
        // if not found
        return "None";
    }
}