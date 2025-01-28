// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract simpleVault {
    mapping (address => uint) public account;
    event Deposit(address indexed sender, uint amounts);
    event Fallback(string message);

    fallback() external { 
        emit Fallback("Got Fallback!");
     }

    function deposit() external payable  {
        require(msg.value > 0, "Amount must be greater than 0!");
        account[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint) {
        return account[msg.sender];
    }
}