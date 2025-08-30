// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleFallback {
    // Status ringkas untuk dicek dari luar
    uint256 public totalReceived; // total ETH yang pernah diterima lewat fallback
    uint256 public calls; // berapa kali fallback terpanggil
    address public lastSender; // pengirim terakhir
    bytes public lastData; // data terakhir (jika ada)

    event FallbackHit(address indexed sender, uint256 value, bytes data);

    // Fallback dipanggil ketika:
    // - Fungsi yang dipanggil tidak ada / selector tidak cocok, ATAU
    // - Kirim ETH dengan data (atau tanpa data jika tidak ada receive()).
    //
    // Kata kunci `payable` diperlukan agar bisa menerima ETH.
    fallback() external payable {
        totalReceived += msg.value;
        calls += 1;
        lastSender = msg.sender;
        lastData = msg.data;

        emit FallbackHit(msg.sender, msg.value, msg.data);
    }

    // (Opsional) fungsi penarikan agar dana yang terkumpul bisa diambil pemilik.
    address public owner = msg.sender;

    function withdraw(address payable to, uint256 amount) external {
        require(msg.sender == owner, "not owner");
        require(address(this).balance >= amount, "insufficient balance");
        (bool ok,) = to.call{value: amount}("");
        require(ok, "withdraw failed");
    }
}
