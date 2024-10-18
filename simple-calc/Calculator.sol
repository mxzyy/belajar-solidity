// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Calculator {

    function add(int256 param1, int256 param2) public pure returns (int256)  {
        return param1 + param2;
    }

    function substract(int256 param1, int256 param2) public pure returns (int256) {
        return param1 - param2;
    }

    function multiplication(int256 param1, int256 param2) public pure returns (int256) {
        return param1 * param2;
    }

    function divide(int256 param1, int256 param2) public pure returns (int256) {
        return param1 / param2;
    }

}
