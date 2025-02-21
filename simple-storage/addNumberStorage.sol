// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {simpleStorage} from "./simpleStorage.sol";

contract addNumberStorage is simpleStorage {
    function store(uint256 _favoriteNumber) public override {
        favouriteNumber = _favoriteNumber + 2;
    }
}