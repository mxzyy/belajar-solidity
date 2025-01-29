// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Foo {
    function printValue(uint _value) public pure returns (uint) {
        require(_value != 0, "Value is 0");
        return _value;
    }
}

contract Bar {
    Foo public fooContract;
    event Log(string message);

    constructor(address _fooAddress) {
        fooContract = Foo(_fooAddress);
    }

    function tryCatchValue(uint _value) public {
        try fooContract.printValue(_value) returns (uint) {
            emit Log("Foo called!");
        } catch Error(string memory reason) {
            // Catch revert with reason
            emit Log(reason);
        } catch {
            emit Log("Failed");
        }
    }
}