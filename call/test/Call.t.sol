// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {A, B} from "../src/Call.sol";

/* -------------------------- Mocks untuk gagal --------------------------- */

/// @dev Callee yang revert dengan reason string
contract BRevertWithReason {
    function foo(string calldata, uint256) external payable returns (bytes32) {
        revert("Nope");
    }
}

/// @dev Callee yang revert TANPA data (no reason)
contract BRevertNoReason {
    function foo(string calldata, uint256) external payable returns (bytes32) {
        revert();
    }
}

/* ------------------------------ Test suite ------------------------------ */

contract CalTest is Test {
    A internal a;
    B internal b;
    address internal user;

    // Redeclare event dengan signature yang sama agar bisa dipakai vm.expectEmit
    event Response(bool success, bytes data);
    event FooCalled(address indexed from, uint256 value, string note, uint256 x);

    function setUp() public {
        a = new A();
        b = new B();
        user = address(0xBEEF);
        vm.deal(user, 100 ether);
    }

    function test_CallFunc_Success_StateEventAndValueForwarded() public {
        uint256 sendValue = 1 ether;

        // Expect event dari B (callee). Topic[1] adalah indexed 'from' = address(a)
        vm.expectEmit(true, false, false, true, address(b));
        emit FooCalled(address(a), sendValue, "call foo", 123);

        // Expect event dari A (caller) - success=true dan data=abi.encode(bytes32("ok"))
        bytes32 expectedTag = keccak256("ok");
        vm.expectEmit(false, false, false, true, address(a));
        emit Response(true, abi.encode(expectedTag));

        // user -> A.callFunc -> B.foo
        vm.prank(user);
        a.callFunc{value: sendValue}(address(b));

        // Cek state berubah
        assertEq(b.myVar(), 123, "myVar should be 123");

        // ETH ter-forward ke B, A tidak menahan saldo
        assertEq(address(b).balance, sendValue, "ETH should be forwarded to B");
        assertEq(address(a).balance, 0, "A should not retain ETH");
    }

    function test_CallFunc_RevertsAndBubblesReasonString() public {
        BRevertWithReason bad = new BRevertWithReason();

        // A harus bubble reason "Nope" via _getRevertMsg
        vm.expectRevert(bytes("Nope"));
        vm.prank(user);
        a.callFunc{value: 0}(address(bad));
    }

    function test_CallFunc_RevertsWithLowLevelFallbackMessageWhenNoReason() public {
        BRevertNoReason bad = new BRevertNoReason();

        // Callee revert tanpa data -> _getRevertMsg() mengembalikan "low-level call failed"
        vm.expectRevert(bytes("low-level call failed"));
        vm.prank(user);
        a.callFunc{value: 0}(address(bad));
    }

    /// Opsional: verifikasi bahwa Response.data bisa didecode ke bytes32 tag "ok"
    function test_ResponseEvent_ReturnDataDecodable() public {
        vm.recordLogs();

        vm.prank(user);
        a.callFunc{value: 0}(address(b));

        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 responseSig = keccak256("Response(bool,bytes)");
        bool found;
        bytes32 decodedTag;

        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].emitter == address(a) && logs[i].topics.length > 0 && logs[i].topics[0] == responseSig) {
                (bool success, bytes memory data) = abi.decode(logs[i].data, (bool, bytes));
                assertTrue(success, "Response.success should be true");
                decodedTag = abi.decode(data, (bytes32));
                found = true;
                break;
            }
        }

        assertTrue(found, "Response event not found");
        assertEq(decodedTag, keccak256("ok"), "decoded tag should equal keccak256('ok')");
    }
}
