// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract PayableDemo {
    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    event Forwarded(address indexed to, uint256 amount);

    address public owner;
    mapping(address => uint256) public balanceOf;

    // Simple non-reentrancy guard (tanpa OpenZeppelin)
    bool private locked;

    modifier nonReentrant() {
        require(!locked, "Reentrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /* ========================= PAYABLE IN ========================= */

    // 1) Deposit via fungsi (msg.value diterima karena payable)
    function deposit() external payable {
        require(msg.value > 0, "No ETH");
        balanceOf[msg.sender] += msg.value; // catat saldo user
        emit Deposited(msg.sender, msg.value);
    }

    // 2) Terima ETH transfer “plain” (tanpa data)
    receive() external payable {
        // Di sini kita TIDAK menambah balanceOf agar contoh jelas bahwa
        // deposit() adalah jalur yang "tercatat". Transfer plain tetap masuk
        // ke saldo kontrak (address(this).balance).
        emit Deposited(msg.sender, msg.value);
    }

    // 3) Terima panggilan dengan data yang tidak cocok (opsional)
    fallback() external payable {
        if (msg.value > 0) {
            emit Deposited(msg.sender, msg.value);
        }
    }

    /* ========================= PAYABLE OUT ========================= */

    // A) User menarik dana yang sudah ia deposit (pakai CEI + call)
    function withdraw(uint256 amount) external nonReentrant {
        require(balanceOf[msg.sender] >= amount, "Insufficient");
        balanceOf[msg.sender] -= amount; // Effects
        (bool ok,) = payable(msg.sender).call{value: amount}(""); // Interaction
        require(ok, "Withdraw failed");
        emit Withdrawn(msg.sender, amount);
    }

    // B) Owner mem-forward dana dari SALDO KONTRAK (bukan dari mapping)
    //    Cocok untuk menyalurkan donasi yang masuk via receive()
    function forward(address payable to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "Zero addr");
        require(address(this).balance >= amount, "Contract balance low");
        (bool ok,) = to.call{value: amount}("");
        require(ok, "Forward failed");
        emit Forwarded(to, amount);
    }

    /* ========================= VIEW HELPERS ========================= */

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
