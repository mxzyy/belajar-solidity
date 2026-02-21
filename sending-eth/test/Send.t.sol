// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {ETHSenderPlayground, ReceiverMinimal, ReceiverExpensive} from "../src/Send.sol";

/* --------- PENTING: Reenterer harus top-level, bukan di dalam kontrak test --------- */
contract Reenterer {
    ETHSenderPlayground public p;

    constructor(ETHSenderPlayground _p) {
        p = _p;
    }

    // Saat menerima ETH dari withdraw(), coba reenter withdraw() lagi → harus gagal karena nonReentrant
    receive() external payable {
        try p.withdraw() {} catch {}
    }

    function trigger() external {
        p.withdraw();
    }
}

contract ETHSenderPlaygroundTest is Test {
    ETHSenderPlayground internal p;
    ReceiverMinimal internal rMin;
    ReceiverExpensive internal rExp;

    function setUp() public {
        p = new ETHSenderPlayground();
        rMin = new ReceiverMinimal();
        rExp = new ReceiverExpensive();

        // Danai test contract lalu setor ke playground
        vm.deal(address(this), 100 ether);
        p.deposit{value: 10 ether}();
    }

    /* -------------------------------------------------------------
                                Transfer / Send / Call
       ------------------------------------------------------------- */

    function testTransferToReceiverMinimalSucceeds() public {
        uint256 beforeBal = address(rMin).balance;
        p.payWithTransfer(payable(address(rMin)), 0.1 ether);
        assertEq(address(rMin).balance, beforeBal + 0.1 ether, "transfer -> minimal should succeed");
    }

    function testSendToReceiverMinimalSucceeds() public {
        uint256 beforeBal = address(rMin).balance;
        p.payWithSend(payable(address(rMin)), 0.1 ether);
        assertEq(address(rMin).balance, beforeBal + 0.1 ether, "send -> minimal should succeed");
    }

    function testTransferToReceiverExpensiveReverts() public {
        vm.expectRevert(); // transfer auto-revert tanpa reason
        p.payWithTransfer(payable(address(rExp)), 0.1 ether);
    }

    function testSendToReceiverExpensiveRevertsWithMessage() public {
        vm.expectRevert(bytes("send failed (likely >2300 gas in receiver)"));
        p.payWithSend(payable(address(rExp)), 0.1 ether);
    }

    function testCallToReceiverExpensiveSucceeds() public {
        uint256 beforeBal = address(rExp).balance;
        p.payWithCall(payable(address(rExp)), 0.1 ether);
        assertEq(address(rExp).balance, beforeBal + 0.1 ether, "call -> expensive should succeed");
    }

    /* -------------------------------------------------------------
                                Pull Payments
       ------------------------------------------------------------- */

    function testPullPaymentWithdrawWorks() public {
        address alice = address(0xA11CE);
        uint256 aliceBefore = alice.balance;

        p.credit{value: 1 ether}(alice);
        assertEq(p.withdrawable(alice), 1 ether, "credited amount mismatch");

        vm.prank(alice);
        p.withdraw();

        assertEq(alice.balance, aliceBefore + 1 ether, "withdraw should transfer 1 ether to Alice");
        assertEq(p.withdrawable(alice), 0, "withdrawable should be zero after withdraw");
    }

    /* -------------------------------------------------------------
                         Reentrancy protection on withdraw
       ------------------------------------------------------------- */
    function testWithdrawBlocksReentrancy() public {
        Reenterer attacker = new Reenterer(p);
        uint256 beforeAttacker = address(attacker).balance;

        p.credit{value: 1 ether}(address(attacker));
        assertEq(p.withdrawable(address(attacker)), 1 ether);

        attacker.trigger(); // reenter akan ditolak oleh nonReentrant, tx utama tetap sukses

        assertEq(address(attacker).balance, beforeAttacker + 1 ether, "attacker should receive exactly 1 ether");
        assertEq(p.withdrawable(address(attacker)), 0, "withdrawable should be zero");
    }
}
