// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface ICounter {
    function increment() external;
    function decrement() external;
}

contract Counter is ICounter {
    uint public number;

    function increment() external  override {
        number += 1;
    }

    function decrement() external override  {
        number -= 1;
    }
}