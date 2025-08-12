// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/AE.sol";

contract AETest is Test {
    AE private ae; // kontrak yang diuji
    address private alice; // penerima payout

    /* ─────────────────────────────  SET-UP  ───────────────────────────── */
    function setUp() public {
        ae = new AE();

        // siapkan akun penerima (EOA) dengan 0 ETH
        alice = vm.addr(1);

        // isi kontrak dengan 1 ether sebagai saldo awal
        vm.deal(address(this), 1 ether);
        (bool ok,) = address(ae).call{value: 1 ether}(""); // trigger receive()
        require(ok, "funding failed");
    }

    /* ─────────────────────── 1. bankBalance() bekerja ─────────────────── */
    function testBankBalance() public view {
        assertEq(ae.bankBalance(), 1 ether);
    }

    /* ─────── 2. payout sukses + event EthTransferred ter-emit ─────────── */
    function testPayoutEmitsEvent() public {
        uint256 sendAmt = 0.25 ether;

        // siapkan ekspektasi event
        vm.expectEmit(true, true, false, true);
        emit EthTransferred(address(ae), alice, sendAmt, block.timestamp);

        // panggil payout
        ae.payout(payable(alice), sendAmt);

        // saldo kontrak berkurang, saldo Alice bertambah
        assertEq(ae.bankBalance(), 1 ether - sendAmt);
        assertEq(alice.balance, sendAmt);
    }

    /* ─────────── 3. payout gagal (saldo kurang) harus revert ──────────── */
    function testPayoutRevertOnInsufficient() public {
        vm.expectRevert("insufficient");
        ae.payout(payable(alice), 2 ether); // kontrak hanya punya 1 ether
    }

    /* ─────────── 4. revert jika low-level call send gagal ─────────────── */
    function testPayoutRevertOnSendFail() public {
        // buat kontrak penerima yang me-revert di receive()
        RevertingReceiver bad = new RevertingReceiver();

        vm.expectRevert("send failed");
        ae.payout(payable(address(bad)), 0.1 ether);
    }

    /* ─── Redeclare event supaya expectEmit mengenali tanda tangan tepat ── */
    event EthTransferred(address indexed from, address indexed to, uint256 amount, uint256 blockTimestamp);
}

/* ═════════════════════  Kontrak penerima yang selalu revert  ════════════ */
contract RevertingReceiver {
    receive() external payable {
        revert("nope");
    }
}
