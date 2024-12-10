// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Faucet {
    receive() external payable { }

    function withdraw(uint amount) public {
        require(amount <= 100000000000000000,"Withdrawal amount exceeds limit");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed.");
    }
}

