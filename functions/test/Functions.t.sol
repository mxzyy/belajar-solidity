// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/FunctionGallery.sol";

contract FunctionGalleryTest is Test {
    FunctionGallery private gallery;
    Target private target;

    function setUp() public {
        vm.deal(address(this), 20 ether); // isi saldo tester

        /* deploy gallery dengan counter awal 0 dan ether 1 ETH */
        gallery = new FunctionGallery{value: 1 ether}(0);
        target = new Target();
    }

    /* ---------- 1. Constructor & getter ---------- */
    function testConstructor() public view {
        assertEq(gallery.owner(), address(this));
        assertEq(gallery.current(), 0);
        assertEq(address(gallery).balance, 1 ether);
    }

    /* ---------- 2. set(), inc() overload ---------- */
    function testSetAndIncrement() public {
        gallery.set(10);
        assertEq(gallery.current(), 10);

        gallery.inc(); // +1
        gallery.inc(9); // +9
        assertEq(gallery.current(), 20);
    }

    /* ---------- 3. view & pure ---------- */
    function testPureAdd() public view {
        assertEq(gallery.add(3, 4), 7);
    }

    /* ---------- 4. payable deposit ---------- */
    function testDeposit() public {
        uint256 start = address(gallery).balance;
        gallery.deposit{value: 2 ether}();
        assertEq(address(gallery).balance, start + 2 ether);
    }

    /* ---------- 5. function pointer ---------- */
    function testFunctionPointer() public view {
        assertEq(gallery.callAddViaPtr(5, 6), 11);
    }

    /* ---------- 6. delegatecall demo ---------- */
    function testDelegateSet() public {
        // memastikan tidak revert; owner (slot-0) akan tertimpa, itu sengaja
        gallery.delegateSet(address(target), 555);
    }

    /* ---------- 7. receive / fallback ---------- */
    function testReceiveAndFallback() public {
        // receive(): kirim ETH tanpa data
        (bool okRecv,) = address(gallery).call{value: 1 wei}("");
        assertTrue(okRecv, "receive() failed");

        // fallback(): selector tak dikenal
        (bool okFb,) = address(gallery).call(abi.encodeWithSignature("ghost()"));
        assertTrue(okFb, "fallback() failed");
    }
}
