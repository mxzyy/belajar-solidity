// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Library {
    uint public value;

    function setValue(uint _value) public {
        value = _value;
    }
}

// call function di contract library, tapi pake state dari contract si caller

contract Proxy {
    uint public value;

    function delegatecallSetValue(address _library, uint _value) public {
        (bool success, ) = _library.delegatecall(abi.encodeWithSignature("setValue(uint256)", _value));
        require(success, "Delegatecall failed");
    }
}