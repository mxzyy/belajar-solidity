// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {SimpleFallback} from "../src/Fallback.sol";

contract SimpleFallbackTest is Test {
    // Tambahkan ini supaya address(this) bisa menerima ETH
    receive() external payable {}

    // Deklarasi event yang sama dengan di kontrak agar bisa pakai expectEmit
    event FallbackHit(address indexed sender, uint256 value, bytes data);

    SimpleFallback internal simple;
    address internal owner;
    address internal alice;
    address internal bob;

    function setUp() public {
        simple = new SimpleFallback();
        owner = address(this);
        alice = address(0xA11CE);
        bob = address(0xB0B);

        vm.deal(owner, 100 ether);
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
    }

    function testFallbackNoDataHitsAndAccumulates() public {
        uint256 beforeCalls = simple.calls();
        uint256 beforeTotal = simple.totalReceived();

        // Expect event dari alamat kontrak simple
        vm.expectEmit(true, false, false, true, address(simple));
        emit FallbackHit(address(this), 1 ether, bytes(""));

        // Kirim ETH TANPA data -> fallback() terpicu (karena tidak ada receive())
        (bool ok,) = payable(address(simple)).call{value: 1 ether}("");
        assertTrue(ok, "low-level call failed");

        assertEq(simple.calls(), beforeCalls + 1, "calls should increment");
        assertEq(simple.totalReceived(), beforeTotal + 1 ether, "totalReceived should add up");
        assertEq(simple.lastSender(), address(this), "lastSender mismatch");
        assertEq(simple.lastData().length, 0, "lastData should be empty");
    }

    function testFallbackWithData() public {
        bytes memory data = hex"deadbeef";

        // Kirim ETH DENGAN data -> fallback() terpicu
        (bool ok,) = payable(address(simple)).call{value: 0.5 ether}(data);
        assertTrue(ok);

        assertEq(simple.totalReceived(), 0.5 ether, "totalReceived mismatch");
        assertEq(simple.calls(), 1, "calls mismatch");
        assertEq(simple.lastSender(), address(this), "lastSender mismatch");
        // Bandingkan bytes via hash biar pasti
        assertEq(keccak256(simple.lastData()), keccak256(data), "lastData mismatch");
    }

    function testWithdrawOnlyOwner() public {
        // Danai kontrak dulu melalui fallback
        (bool ok,) = payable(address(simple)).call{value: 1 ether}("");
        assertTrue(ok);

        // Non-owner tidak boleh withdraw
        vm.prank(bob);
        vm.expectRevert(bytes("not owner"));
        simple.withdraw(payable(bob), 0.1 ether);
    }

    function testWithdrawInsufficientBalanceReverts() public {
        vm.expectRevert(bytes("insufficient balance"));
        simple.withdraw(payable(owner), 1); // tidak ada saldo
    }

    function testWithdrawTransfersBalanceToOwner() public {
        // deposit 2 ETH via fallback
        (bool ok,) = payable(address(simple)).call{value: 2 ether}("");
        assertTrue(ok);

        uint256 ownerBefore = owner.balance;

        // owner tarik 1.25 ETH ke address(this) (sekarang sudah bisa terima)
        simple.withdraw(payable(owner), 1.25 ether);

        assertEq(owner.balance, ownerBefore + 1.25 ether, "owner balance should increase");
        assertEq(address(simple).balance, 0.75 ether, "contract balance should decrease");
    }
}
