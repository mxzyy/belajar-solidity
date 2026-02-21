// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract simpleEscrow {
    /// ---- STATE
    address public immutable payer; // siapa yang wajib menyetor dana
    address public immutable payee; // penerima final
    uint256 public immutable releaseTime; // detik Unix: kapan dana boleh di-klaim

    bool public claimed;

    /// ---- EVENTS
    event Deposited(address indexed from, uint256 amount);
    event Claimed(address indexed to, uint256 amount);

    /// ---- CONSTRUCTOR
    constructor(address _payer, address _payee, uint256 _releaseAfter) payable {
        require(_payer != address(0) && _payee != address(0), "zero addr");
        require(_releaseAfter > 0, "delay 0");

        payer = _payer; // <-- di-set sekali, immutable
        payee = _payee; // immutable
        releaseTime = block.timestamp + _releaseAfter;

        if (msg.value > 0) {
            emit Deposited(msg.sender, msg.value); // dana seed opsional
        }
    }

    /* ──────────  FUNGSI DEPOSIT  ─────────── */
    function deposit() external payable {
        require(msg.sender == payer, "only payer");
        emit Deposited(msg.sender, msg.value);
    }

    /* ──────────  FUNGSI CLAIM  ───────────── */
    function claim() external {
        require(block.timestamp >= releaseTime, "too early");
        require(!claimed, "already");
        claimed = true;

        uint256 amt = address(this).balance;
        (bool ok,) = payee.call{value: amt}("");
        require(ok, "send fail");

        emit Claimed(payee, amt);
    }
}
