// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Counter.sol";

contract CounterTest is Test {
    Counter private counter;
    address private alice = vm.addr(1); // akun uji non-owner

    receive() external payable {}

    function setUp() public {
        // deploy & kirim 1 ether ke kontrak
        counter = new Counter{value: 1 ether}();
        // beri saldo 5 ETH ke Alice
        vm.deal(alice, 5 ether);
    }

    /* --- 1. owner dapat set & read counter --- */
    function testSetAndReadCounter() public {
        counter.setCounter(42);
        assertEq(counter.counter(), 42);
    }

    /* --- 2. deposit oleh alamat mana pun --- */
    function testDeposit() public {
        uint256 beforeBal = address(counter).balance;

        vm.prank(alice); // jalankan call dari Alice
        (bool ok,) = address(counter).call{value: 2 ether}("");
        require(ok, "receive failed");

        assertEq(address(counter).balance, beforeBal + 2 ether);
    }

    /* --- 3. withdraw oleh owner + nonReentrant --- */
    function testWithdraw() public {
        uint256 startOwnerBal = address(this).balance;
        counter.withdraw(payable(address(this)), 0.5 ether);
        assertEq(address(counter).balance, 0.5 ether); // 1 − 0.5
        assertEq(address(this).balance, startOwnerBal + 0.5 ether);
    }
}
