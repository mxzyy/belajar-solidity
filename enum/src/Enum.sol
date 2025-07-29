// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Enum {
    enum someState {
        Created,
        Pending,
        Proceed,
        Done
    }

    someState state;
    someState constant defaultState = someState.Created;

    function getState() public view returns (someState) {
        return state;
    }

    function getDefaultState() public pure returns (someState) {
        return defaultState;
    }

    function getMinState() public pure returns (someState) {
        return type(someState).min;
    }

    function getMaxState() public pure returns (someState) {
        return type(someState).max;
    }

    function setState(uint256 _index) public {
        require(_index <= uint8(type(someState).max), "index out of range");
        state = someState(_index);
    }
}
