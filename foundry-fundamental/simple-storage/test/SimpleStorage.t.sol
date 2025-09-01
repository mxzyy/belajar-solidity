// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

/* --------------------------------------------- */
/*                  IMPORTS                      */
/* --------------------------------------------- */

import {DeploySimpleStorage} from "../script/SimpleStorage.s.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";
import {Test} from "forge-std/Test.sol";

contract SimpleStorageTest is Test {
    /// @notice define a new instance of SimpleStorage
    SimpleStorage public simpleStorage;

    /// @notice define a new instance of DeploySimpleStorage & run the deployment
    function setUp() external {
        DeploySimpleStorage deployer = new DeploySimpleStorage();
        simpleStorage = deployer.run();
    }

    function testStoreNumber() public {
        /// @notice define the number to store in SimpleStorage.store
        uint256 favoriteNumber = 777;

        /// @notice store the favorite number
        simpleStorage.store(favoriteNumber);

        /// @notice verify that the stored number is correct
        assertEq(simpleStorage.retrieve(), favoriteNumber);
    }

    function testCreatePerson() public {
        string memory name = "Alice";
        uint256 expectedNumber = 999;
        simpleStorage.addPerson(name, expectedNumber);
        uint256 retrievedNumber = simpleStorage.nameToFavoriteNumber(name);
        assert(retrievedNumber == expectedNumber);
    }
}
