// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Parent {
    function parentFunc() public pure returns (string memory) {
        return "This is parent func!";
    }
}

contract Child is Parent {
    function callParentFunc() public pure returns (string memory) {
        return parentFunc();
    }

    function childFunc() public pure returns (string memory) {
        return "This is child func!";
    }
}
