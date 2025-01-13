// SPDX-License-Identifier: MIT
pragma solidity =0.8.26;

contract Mapping {
    mapping (string => address) public localLedger;

    function getAddr(string calldata _owner) public view returns (address) {
        return localLedger[_owner];
    }

    function setAddr(string calldata _owner, address _addr) public {
        localLedger[_owner] = _addr;
    }

    function removeAddr(string calldata _owner) public {
        delete localLedger[_owner];
    }

}