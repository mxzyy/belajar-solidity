// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract ifElse {
    uint number;

    function setNumber(uint _number) public {
        number = _number;
    }

    function getNumber() public view returns (uint) {
        return number;
    }

    function isOdd() public view returns (bool) {
        if (number % 2 != 0) {
            return true;
        } else {
            return false;
        }
    }

    function isEven() public view returns (bool) {
        if (number % 2 == 0) {
            return true;
        } else {
            return false;
        }
    }
}
