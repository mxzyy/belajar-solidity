// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Events {
    event Called(address indexed caller, string funcName);

    function callFunction() external returns (string memory) {
        emit Called(msg.sender, "callFunction");
        return "Function Called";
    }
}
