// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract simpleLock {
    struct TimeData {
        uint256 lastTime;
        uint256 duration;
    }

    address payable public owner;
    uint public duration;
    mapping(address => TimeData) public userData;

    constructor() {
        owner = payable(msg.sender);
    }

    function setDuration(uint256 _duration) public {
        userData[msg.sender].lastTime = block.timestamp;
        userData[msg.sender].duration = _duration;
    }

    function LockSome(uint _duration) public payable {
        require(msg.value > 0, "Must send some Ether");
        duration = _duration;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function checkDuration() public view returns (bool) {
        TimeData memory data = userData[msg.sender];
        
        // Kalau belum pernah set durasi, return true
        if (data.lastTime == 0) {
            return true;
        }
        
        return block.timestamp >= data.lastTime + data.duration;
    }
}