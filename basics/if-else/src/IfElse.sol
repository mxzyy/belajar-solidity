// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract IfElse {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function getNumber() public view returns(uint256){
        return number;
    }

    function isOdd() public view returns(bool){
        if (number % 2 != 0) {
            return true;
        } else {
            return false;
        }
    }
}
