// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract errorHandling {
    
    function rquire(uint _x) public pure {
        require(_x < 10, "X is not more than 10");
    }

    function rvert(uint _x) public pure  {
        if (_x < 10) {
            revert("loginkan");
        }
    }

    function asert(uint _x) public pure returns (string memory) {
        assert(_x < 10);
        return "Done";
    }
}