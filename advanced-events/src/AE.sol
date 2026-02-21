// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract AE {
    /// EventDrivenArchitecture, on-chain contract (producer) -> off-chain services (consumer)
    /// @notice  Dicatat setiap ada ETH pindah.
    /// `indexed` dipakai agar UI / backend bisa filter cepat per alamat.

    event EthTransferred(address indexed from, address indexed to, uint256 amount, uint256 blockTimestamp);

    /// setor ETH ke kontrak (deposit)
    receive() external payable {}

    /// kirim ETH dari saldo kontrak → penerima
    function payout(address payable to, uint256 amount) external {
        require(address(this).balance >= amount, "insufficient");

        // transfer ETH
        (bool ok,) = to.call{value: amount}("");
        require(ok, "send failed");

        // *** inilah publish event ***
        emit EthTransferred(address(this), to, amount, block.timestamp);
    }

    /// helper baca saldo kontrak
    function bankBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
