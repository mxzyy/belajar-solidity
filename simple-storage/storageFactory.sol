// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {simpleStorage} from "./simpleStorage.sol";

contract storageFactory {
    simpleStorage[] public listsSimpleStorageContracts;
    
    function createSimpleStorageContract() public {
        simpleStorage simpleStorageVariable = new simpleStorage();
        listsSimpleStorageContracts.push(simpleStorageVariable);
    }

    function sfStore(uint256 _simpleStorageIndex, uint256 _simpleStorageNumber) public  {
        listsSimpleStorageContracts[_simpleStorageIndex].store(_simpleStorageNumber);
    }

    function sfGet(uint256 _simpleStorageIndex) public view  returns (uint256) {
        return listsSimpleStorageContracts[_simpleStorageIndex].retriveNumber();
    }
}