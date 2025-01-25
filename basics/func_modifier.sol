// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract funcModifier {
    address public owner;
    bool public locked;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _; // Execute function body
    }

    function ownerFunc() public view onlyOwner returns (string memory) {
        return "You're owner";
    }

    function notOwnerFunc() public pure returns (string memory) {
        return "This is public function that anybody can call!";
    }
}