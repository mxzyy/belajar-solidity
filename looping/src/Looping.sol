// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/console.sol";

contract Looping {
    function for_loop() public pure returns (uint256) {
        uint i;
        for (i = 0; i < 10; i++) {
            console.log("i =", i);
        }
        return i;
    }

    function while_loop() public pure returns (uint256) {
        uint256 i;
        while (i < 10) {
            console.log("i =", i);
            i++;
        }
        return i;
    }

    function do_while() public pure returns (uint256) {
        uint i;
        do {
            console.log("i =", i);
            i++;
        } while (i < 10);
        return i;
    }
}