// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contract utama
contract MainContract {
    uint private privateData;
    uint public publicData;
    
    constructor() {
        privateData = 100;
        publicData = 200;
    }
    
    function privateFunction() private view returns(uint) {
        return privateData;
    }
    
    function publicFunction() public view returns(uint) {
        return privateFunction() + publicData;
    }

    function internalFunction() internal view returns(uint) {
        return privateData * 2;
    }

    function callPrivateFunc() public  view  returns (uint) {
        return privateFunction();
    }

    function callInternalFunc() public  view  returns (uint) {
        return internalFunction();
    }

    function externalFunction() external view returns(uint) {
        return publicData * 3;
    }
}

contract Caller {
    MainContract mainContract;
    constructor(address _mainContract) {
        mainContract = MainContract(_mainContract);
    }

    function callPublicFunction() public view returns (uint) {
        return mainContract.publicFunction();
    }

    function callExternalFunction() public view returns (uint) {
        return mainContract.externalFunction();
    }
}

