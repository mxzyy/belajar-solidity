// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Constructor.sol";

contract SimpleEscrowTest is Test {
    /* -------------------------------------------------- */
    /*  Test actors & constants                           */
    /* -------------------------------------------------- */
    address private deployer = vm.addr(0xA); // akun yang men-deploy escrow
    address private payer = vm.addr(0xB); // wajib setor
    address private payee = vm.addr(0xC); // penerima akhir

    uint256 private constant WAIT = 7 days; // jeda rilis
    uint256 private constant SEED = 1 ether; // dana awal saat deploy

    simpleEscrow private esc;

    /* -------------------------------------------------- */
    /*  SET-UP                                            */
    /* -------------------------------------------------- */
    function setUp() public {
        vm.deal(deployer, 10 ether);
        vm.startPrank(deployer);

        // deploy kontrak dengan 1 ETH seed
        esc = new simpleEscrow{value: SEED}(payer, payee, WAIT);

        vm.stopPrank();

        // beri saldo awal ke payer untuk pengujian deposit
        vm.deal(payer, 5 ether);
    }

    /* -------------------------------------------------- */
    /*  1. Constructor sets immutables & seed             */
    /* -------------------------------------------------- */
    function testConstructorInit() public view {
        assertEq(esc.payer(), payer);
        assertEq(esc.payee(), payee);
        assertApproxEqAbs(
            esc.releaseTime(),
            block.timestamp + WAIT,
            2 // ±2 detik margin eksekusi
        );
        assertEq(address(esc).balance, SEED);
    }

    /* -------------------------------------------------- */
    /*  2. Only payer can deposit                         */
    /* -------------------------------------------------- */
    function testDepositByPayer() public {
        vm.prank(payer);
        esc.deposit{value: 0.5 ether}();

        assertEq(address(esc).balance, SEED + 0.5 ether);
    }

    function testDepositByNotPayerReverts() public {
        vm.prank(payee); // payee bukan payer
        vm.expectRevert("only payer");
        esc.deposit{value: 0}(); // kirim 0 => tak butuh saldo
    }

    /* -------------------------------------------------- */
    /*  3. Claim flow                                     */
    /* -------------------------------------------------- */
    function testClaimAfterTime() public {
        // Fast-forward time to just after releaseTime
        vm.warp(block.timestamp + WAIT + 1);

        uint256 beforeEsc = address(esc).balance;
        uint256 beforePayee = payee.balance;

        vm.prank(payee);
        esc.claim();

        assertEq(address(esc).balance, 0);
        assertEq(payee.balance, beforePayee + beforeEsc);
        assertTrue(esc.claimed());
    }

    function testClaimTooEarlyReverts() public {
        vm.prank(payee);
        vm.expectRevert("too early");
        esc.claim();
    }

    function testDoubleClaimReverts() public {
        // first claim succeeds
        vm.warp(block.timestamp + WAIT + 1);
        vm.prank(payee);
        esc.claim();

        // second claim should revert "already"
        vm.prank(payee);
        vm.expectRevert("already");
        esc.claim();
    }
}
