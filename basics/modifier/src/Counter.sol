// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// ░░░  Minimal Re-entrancy Guard  ░░░
abstract contract ReentrancyGuard {
    error ReentrantCall();

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status = _NOT_ENTERED;

    modifier nonReentrant() {
        if (_status == _ENTERED) revert ReentrantCall();
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

/// ░░░  Counter Wallet  ░░░
contract Counter is ReentrancyGuard {
    /* ────────  STORAGE  ──────── */
    uint256 public counter; // contoh state
    address public immutable owner; // ditetapkan 1×

    /* ────────  EVENTS  ───────── */
    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    event CounterSet(uint256 newValue);

    /* ────────  ERRORS  ───────── */
    error NotOwner();

    /* ────────  MODIFIERS  ────── */
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /* ────────  CONSTRUCTOR  ──── */
    constructor() payable {
        owner = msg.sender; // deployer menjadi owner
        counter = 0;
        if (msg.value > 0) emit Deposited(msg.sender, msg.value);
    }

    /* ────────  MUTATIVE LOGIC  ─ */
    function setCounter(uint256 value) external onlyOwner {
        counter = value;
        emit CounterSet(value);
    }

    /* ────────  PAYABLE   ─────── */
    /// anyone may deposit ETH
    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    /// owner-only withdraw pattern, with re-entrancy guard
    function withdraw(address payable to, uint256 amount) external onlyOwner nonReentrant {
        require(address(this).balance >= amount, "insufficient balance");
        (bool ok,) = to.call{value: amount}("");
        require(ok, "transfer failed");
        emit Withdrawn(to, amount);
    }

    /* ────────  VIEW HELPERS  ─── */
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
