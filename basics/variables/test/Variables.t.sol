// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Variables} from "../src/Variables.sol";

contract VariablesTest is Test {
    Variables public variables;

    function setUp() public {
        variables = new Variables();
    }

    function test_demoLocalVariables() public {
        uint256 result = variables.demoLocalVariables();
        assertEq(result, 456);
    }

    function test_SetText() public {
        variables.setText("awawa");
        assertEq(variables.getText(), "awawa");
    }

    function test_SetSmallNum() public {
        variables.setNum(100);
        assertEq(variables.getNum(), 100);
    }

    function test_SetFlag() public {
        variables.setFlag(false);
        assertEq(variables.getFlag(), false);
    }

    // =========================================================
    // BLOCK.* GLOBAL VARIABLE TESTS (using Foundry cheatcodes)
    // =========================================================

    function test_GetBlockTimestamp() public {
        // vm.warp() -> manipulate block.timestamp
        vm.warp(1_000_000);
        assertEq(variables.getBlockTimestamp(), 1_000_000);
    }

    function test_GetBlockNumber() public {
        // vm.roll() -> manipulate block.number
        vm.roll(999);
        assertEq(variables.getBlockNumber(), 999);
    }

    function test_GetBlockChainId() public {
        // vm.chainId() -> manipulate block.chainid
        vm.chainId(1); // simulate mainnet
        assertEq(variables.getBlockChainId(), 1);
    }

    function test_GetMsgSender() public {
        address alice = makeAddr("alice");

        // vm.prank() -> set msg.sender for the NEXT call only
        vm.prank(alice);
        assertEq(variables.getMsgSender(), alice);
    }

    function test_GetMsgValue() public {
        address alice = makeAddr("alice");

        // vm.deal() -> give ETH to an address
        vm.deal(alice, 1 ether);

        // vm.prank() also forwards ETH when combined with {value: ...}
        vm.prank(alice);
        uint256 sent = variables.getMsgValue{value: 0.5 ether}();
        assertEq(sent, 0.5 ether);
    }
}
