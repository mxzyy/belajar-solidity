// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./Foo.sol";
import {Unauthorized, add, Point} from "./Foo.sol";

contract Import {
    Foo public foo = new Foo();

    function getFooName() public view returns (string memory) {
        return foo.name();
    }
}
