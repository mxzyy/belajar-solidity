// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract DepositContract {
    address payable public owner;

    // Constructor untuk menyimpan alamat pemilik kontrak
    constructor() {
        owner = payable(msg.sender);
    }

    // Fungsi untuk menerima Ether ke dalam kontrak
    function deposit() public payable {
        require(msg.value > 0, "Must send some Ether");
    }

    // Fungsi untuk mengecek saldo kontrak
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
