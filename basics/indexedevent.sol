// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract IndexedEventExample {
    // Deklarasi event dengan indexed parameter
    event Transfer(
        address indexed from, 
        address indexed to, 
        uint256 amount
    );

    mapping(address => uint256) public balances;

    // Fungsi untuk melakukan transfer
    function transfer(address _to, uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Saldo tidak mencukupi");
        
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;

        // Memanggil event dengan indexed parameter
        emit Transfer(msg.sender, _to, _amount);
    }

    // Fungsi untuk deposit
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
}