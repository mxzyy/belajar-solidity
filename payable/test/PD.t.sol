// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/PD.sol";

interface IPayableDemo {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function balanceOf(address) external view returns (uint256);
}

contract PayableDemoTest is Test {
    PayableDemo demo;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob"); // akan menerima forward
    address eve = makeAddr("eve"); // non-owner

    function setUp() public {
        demo = new PayableDemo(); // owner = address(this)
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(eve, 10 ether);
        vm.deal(address(this), 10 ether);
    }

    /* -------------------- IN: deposit payable -------------------- */
    function test_DepositRecordsMappingAndContractBalance() public {
        vm.prank(alice);
        demo.deposit{value: 1 ether}();

        assertEq(demo.balanceOf(alice), 1 ether);
        assertEq(address(demo).balance, 1 ether);
    }

    /* -------------------- IN: receive (plain transfer) -------------------- */
    function test_ReceivePlainTransferDoesNotAffectMapping() public {
        // kirim ETH tanpa data -> receive()
        vm.prank(alice);
        (bool ok,) = address(demo).call{value: 0.5 ether}("");
        assertTrue(ok);

        assertEq(address(demo).balance, 0.5 ether);
        assertEq(demo.balanceOf(alice), 0); // mapping tidak berubah untuk jalur plain
    }

    /* -------------------- OUT: withdraw (payable out) -------------------- */
    function test_WithdrawReducesMappingAndSendsEth() public {
        // Alice deposit 2 ETH
        vm.prank(alice);
        demo.deposit{value: 2 ether}();

        uint256 aliceAfterDeposit = alice.balance; // simpan setelah deposit
        assertEq(address(demo).balance, 2 ether);

        // Alice withdraw 1 ETH
        vm.prank(alice);
        demo.withdraw(1 ether);

        // Mapping turun, kontrak berkurang, Alice menerima 1 ETH (abaikan gas)
        assertEq(demo.balanceOf(alice), 1 ether);
        assertEq(address(demo).balance, 1 ether);
        assertEq(alice.balance, aliceAfterDeposit + 1 ether);
    }

    /* -------------------- OUT: forward by owner -------------------- */
    function test_ForwardByOwnerTransfersFromContractBalance() public {
        // kontrak diberi saldo via plain transfer (receive)
        vm.prank(alice);
        (bool ok,) = address(demo).call{value: 1.5 ether}("");
        assertTrue(ok);
        assertEq(address(demo).balance, 1.5 ether);

        uint256 bobBefore = bob.balance;

        // only owner = address(this)
        demo.forward(payable(bob), 1 ether);

        assertEq(address(demo).balance, 0.5 ether);
        assertEq(bob.balance, bobBefore + 1 ether);
    }

    function test_ForwardRevertsIfNotOwner() public {
        // isi saldo kontrak
        vm.prank(alice);
        (bool ok,) = address(demo).call{value: 1 ether}("");
        assertTrue(ok);

        vm.prank(eve);
        vm.expectRevert(bytes("Not owner"));
        demo.forward(payable(bob), 0.5 ether);
    }

    /* -------------------- Reentrancy attempt blocked -------------------- */
    // Attacker mencoba reenter withdraw di receive(), tapi nonReentrant memblokir
    function test_ReentrancyBlockedOnWithdraw() public {
        ReentrantAttacker attacker = new ReentrantAttacker(IPayableDemo(address(demo)));
        vm.deal(address(attacker), 1 ether);

        // Attacker deposit 1 ETH ke mapping
        vm.prank(address(attacker));
        attacker.prime{value: 1 ether}();

        assertEq(demo.balanceOf(address(attacker)), 1 ether);
        assertEq(address(demo).balance, 1 ether);

        // Serang: dalam receive(), dia coba call withdraw lagi (akan gagal & di-catch)
        vm.prank(address(attacker));
        attacker.attack(1 ether);

        // Hasil: hanya 1 kali penarikan berhasil; mapping nol, saldo kontrak kembali 0
        assertEq(demo.balanceOf(address(attacker)), 0);
        assertEq(address(demo).balance, 0);
        // (saldo attacker bertambah ~1 ether; biaya gas diabaikan)
    }
}

/* ---------- Helper attacker (coba reenter tapi swallow revert) ---------- */
contract ReentrantAttacker {
    IPayableDemo public target;

    constructor(IPayableDemo _target) {
        target = _target;
    }

    function prime() external payable {
        target.deposit{value: msg.value}();
    }

    // Saat menerima ETH dari withdraw, coba reenter withdraw lagi
    receive() external payable {
        // Reentrancy akan revert karena guard; kita catch agar receive tidak revert,
        // supaya panggilan .call pada withdraw tetap sukses (ok = true).
        try target.withdraw(0.1 ether) {
            // tidak akan terjadi karena guard
        } catch {
            // swallow
        }
    }

    function attack(uint256 amount) external {
        target.withdraw(amount);
    }
}
