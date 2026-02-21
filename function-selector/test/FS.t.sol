// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FS.sol";

contract MockTarget {
    address public lastTo;
    uint256 public lastAmount;
    uint256 public lastValue;

    // contoh fungsi "ERC20-like" untuk menguji selector & argumen
    function transfer(address to, uint256 amount) external returns (bool) {
        lastTo = to;
        lastAmount = amount;
        return true;
    }

    // contoh fungsi yang revert agar kita cek bubbling revert reason
    function willRevert() external pure {
        revert("nope");
    }

    // fungsi payable untuk test forward ETH
    function payableFunc() external payable {
        lastValue = msg.value;
    }
}

contract ReenterTarget {
    SelectorGateway public gateway;
    address public target;
    bytes public data; // calldata untuk inner exec

    constructor(SelectorGateway _gateway) {
        gateway = _gateway;
    }

    function setInnerCall(address _target, bytes calldata _data) external {
        target = _target;
        data = _data;
    }

    // Dipanggil lewat gateway.exec; di dalamnya mencoba memanggil gateway.exec lagi
    // supaya memicu nonReentrant. Agar lolos onlyOperator, kontrak ini harus
    // didaftarkan sebagai operator di gateway oleh admin test.
    function attack() external {
        gateway.exec(target, data, 0);
    }
}

contract SelectorGatewayTest is Test {
    SelectorGateway internal gateway;
    MockTarget internal mock;
    ReenterTarget internal reenter;

    address internal admin = address(0xA11CE);
    address internal op = address(0x0B0B);
    address internal user = address(0xBEEF);

    function setUp() public {
        vm.label(admin, "ADMIN");
        vm.label(op, "OPERATOR");
        vm.label(user, "USER");

        // deploy
        gateway = new SelectorGateway(admin);
        mock = new MockTarget();
        reenter = new ReenterTarget(gateway);

        vm.label(address(gateway), "GATEWAY");
        vm.label(address(mock), "MOCK");
        vm.label(address(reenter), "REENTER");

        // grant operator
        vm.prank(admin);
        gateway.setOperator(op, true);
    }

    /* -------------------------------------------------------------------------- */
    /*                                BASIC HELPERS                                */
    /* -------------------------------------------------------------------------- */

    function _allow(address target, bytes4 sel, bool ok) internal {
        vm.prank(admin);
        gateway.setAllowedPair(target, sel, ok);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   TESTS                                     */
    /* -------------------------------------------------------------------------- */

    function test_selectorOf_matchesInterface() public view {
        bytes4 s1 = gateway.selectorOf("transfer(address,uint256)");
        bytes4 s2 = MockTarget.transfer.selector; // external fn selector
        assertEq(s1, s2, "selector mismatch");
    }

    function test_exec_success_withSelector() public {
        // allow (target, selector)
        _allow(address(mock), MockTarget.transfer.selector, true);

        // build calldata (selector + args)
        bytes memory data = abi.encodeWithSelector(MockTarget.transfer.selector, user, uint256(1234));

        // exec as operator
        vm.prank(op);
        gateway.exec(address(mock), data, 0);

        // assert state on target
        assertEq(mock.lastTo(), user, "lastTo wrong");
        assertEq(mock.lastAmount(), 1234, "lastAmount wrong");
    }

    function test_exec_success_withSignature() public {
        _allow(address(mock), MockTarget.transfer.selector, true);

        // hasil sama seperti encodeWithSelector
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", user, uint256(42));

        vm.prank(op);
        gateway.exec(address(mock), data, 0);

        assertEq(mock.lastTo(), user, "lastTo wrong");
        assertEq(mock.lastAmount(), 42, "lastAmount wrong");
    }

    function test_exec_revert_whenPairNotAllowed() public {
        // tidak di-allow → harus revert PairNotAllowed
        bytes4 sel = MockTarget.transfer.selector;
        bytes memory data = abi.encodeWithSelector(sel, user, uint256(1));

        vm.prank(op);
        vm.expectRevert(abi.encodeWithSelector(SelectorGateway.PairNotAllowed.selector, address(mock), sel));
        gateway.exec(address(mock), data, 0);
    }

    function test_exec_revert_invalidCalldata() public {
        _allow(address(mock), MockTarget.transfer.selector, true);
        bytes memory badData = hex""; // < 4 byte

        vm.prank(op);
        vm.expectRevert(SelectorGateway.InvalidCalldata.selector);
        gateway.exec(address(mock), badData, 0);
    }

    function test_exec_bubblesTargetRevertReason() public {
        // allow willRevert()
        bytes4 sel = MockTarget.willRevert.selector;
        _allow(address(mock), sel, true);

        bytes memory data = abi.encodeWithSelector(sel);

        vm.prank(op);
        vm.expectRevert(bytes("nope")); // pesan revert dari target harus bubble up
        gateway.exec(address(mock), data, 0);
    }

    function test_exec_valueForwarded() public {
        // allow payableFunc()
        bytes4 sel = MockTarget.payableFunc.selector;
        _allow(address(mock), sel, true);

        bytes memory data = abi.encodeWithSelector(sel);
        uint256 v = 0.123 ether;

        vm.deal(op, v);
        vm.prank(op);
        gateway.exec{value: v}(address(mock), data, v);

        assertEq(mock.lastValue(), v, "value not forwarded");
    }

    function test_exec_revert_onEtherMismatch() public {
        bytes4 sel = MockTarget.payableFunc.selector;
        _allow(address(mock), sel, true);

        bytes memory data = abi.encodeWithSelector(sel);

        vm.deal(op, 1 ether);
        vm.prank(op);
        vm.expectRevert(SelectorGateway.EtherMismatch.selector);
        // kirim 1 wei tapi value argumen 0
        gateway.exec{value: 1}(address(mock), data, 0);
    }

    function test_pause_blocksExec() public {
        // pause
        vm.prank(admin);
        gateway.pause(true);

        bytes4 sel = MockTarget.transfer.selector;
        _allow(address(mock), sel, true);
        bytes memory data = abi.encodeWithSelector(sel, user, 1);

        vm.prank(op);
        vm.expectRevert(SelectorGateway.Paused.selector);
        gateway.exec(address(mock), data, 0);
    }

    function test_onlyOperator_canExec() public {
        _allow(address(mock), MockTarget.transfer.selector, true);
        bytes memory data = abi.encodeWithSelector(MockTarget.transfer.selector, user, 1);

        vm.expectRevert(SelectorGateway.NotOperator.selector);
        gateway.exec(address(mock), data, 0); // msg.sender = address(this), bukan operator
    }

    function test_onlyAdmin_canSetOperator() public {
        vm.expectRevert(SelectorGateway.NotAdmin.selector);
        gateway.setOperator(address(0x1234), true);
    }

    function test_rescueETH() public {
        // Kirim ETH ke gateway
        vm.deal(address(this), 1 ether);
        (bool ok,) = address(gateway).call{value: 0.5 ether}("");
        assertTrue(ok, "seed gateway eth failed");

        // Rescue ke admin
        vm.prank(admin);
        gateway.rescueETH(admin, 0.5 ether);

        assertEq(admin.balance, 0.5 ether, "rescue eth failed");
    }

    function test_nonReentrant_blocksReentry() public {
        // 1) jadikan kontrak reenter sebagai operator supaya lolos onlyOperator pada inner call
        vm.prank(admin);
        gateway.setOperator(address(reenter), true);

        // 2) allow pasangan (mock.transfer)
        _allow(address(mock), MockTarget.transfer.selector, true);

        // 3) set inner call data di reenter
        bytes memory innerData = abi.encodeWithSelector(MockTarget.transfer.selector, user, uint256(7));
        reenter.setInnerCall(address(mock), innerData);

        // 4) allow reenter.attack() juga, agar outer exec bisa memanggilnya
        bytes4 attackSel = ReenterTarget.attack.selector;
        _allow(address(reenter), attackSel, true);

        // 5) panggil exec → outer call ke reenter.attack() → inner call gateway.exec(...) → nonReentrant revert
        bytes memory outerData = abi.encodeWithSelector(attackSel);

        vm.prank(op);
        vm.expectRevert(); // nonReentrant di gateway pakai `revert()` tanpa data
        gateway.exec(address(reenter), outerData, 0);
    }
}
