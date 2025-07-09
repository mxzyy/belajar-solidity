// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Variables {
    // State variables are stored on the blockchain.
    string public text = "Hello";
    uint256 public num = 123;

    // function doSomething() public view {
    //     // Local variables are not saved to the blockchain.
    //     uint256 i = 456;

    //     // Here are some global variables
    //     uint256 timestamp = block.timestamp; // Current block timestamp
    //     address sender = msg.sender; // address of the caller
    // }

    function getTimeStamp() public view returns (uint256) {
        uint256 timestamp = block.timestamp;
        return timestamp;
    }

    function getNow() public view returns (uint256) {
        return block.timestamp;
    }

    function setSomethingNum(uint256 x) public {
        num = x;
    }

    function setSomethingText(string memory y) public {
        text = y;
    }

    function getNum() public view returns(uint256) {
        return num;
    }

    function getStr() public view returns(string memory) {
        return text;
    }
}