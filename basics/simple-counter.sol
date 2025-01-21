// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Counter {
    // Storage variabel counter
    int private counter;

    function get() public view returns (int) {
        return counter;
    }

    function increase() public {
        counter += 1;
    }

    function decrease() public {
        counter -= 1;
    }
}