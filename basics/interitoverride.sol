// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Parent {
    function greet() public pure virtual returns (string memory) {
        return "Hi from Parent Contract";
    }
}

contract Child is Parent {
    function greet() public pure override returns (string memory) {
        return "Hi from Child Contract";
    }
}