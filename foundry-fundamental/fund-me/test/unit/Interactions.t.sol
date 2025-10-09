// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {
    FundMe_Fund_InteractionContract,
    FundMe_Withdraw_InteractionContract,
    IDevOpsTools
} from "../../script/Interaction.s.sol";

interface IFundMeLike {
    function fund() external payable;
    function withdraw() external;
}

contract FundMeStub is Test, IFundMeLike {
    uint256 public totalReceived;
    uint256 public withdrawCount;

    function test__helper_tag() public {}

    function fund() external payable override {
        totalReceived += msg.value;
    }

    function withdraw() external override {
        withdrawCount++;
    }
}

// Fake DevOpsTools untuk test
contract FakeDevOpsTools is IDevOpsTools {
    address public fake;

    constructor(address _fake) {
        fake = _fake;
    }

    function get_most_recent_deployment(string memory, uint256) external view override returns (address) {
        return fake;
    }
}

// --- Harness override broadcast jadi no-op
contract FundHarness is Test, FundMe_Fund_InteractionContract {
    function test__helper_tag() public {}
    function _before() internal override {}
    function _after() internal override {}

    function callFund(address recentCA, uint256 amount) external payable {
        _fundCore(recentCA, amount);
    }

    function callFundPublic(address recentCA) external payable {
        FundMe_Fund_Interaction(recentCA);
    }

    function callRun() external {
        run();
    }

    function setTools(IDevOpsTools _tools) external {
        tools = _tools;
    }
}

contract WithdrawHarness is Test, FundMe_Withdraw_InteractionContract {
    function test__helper_tag() public {}
    function _before() internal override {}
    function _after() internal override {}

    function callWithdraw(address recentCA) external {
        _withdrawCore(recentCA);
    }

    function callWithdrawPublic(address recentCA) external {
        FundMe_Withdraw_Interaction(recentCA);
    }

    function callRun() external {
        run();
    }

    function setTools(IDevOpsTools _tools) external {
        tools = _tools;
    }
}

// Harness untuk nutup jalur broadcast asli
contract BroadcastHarnessFund is FundMe_Fund_InteractionContract {
    function setTools(IDevOpsTools _tools) external {
        tools = _tools;
    }

    function callDirect(address ca) external {
        FundMe_Fund_Interaction(ca);
    }
}

contract BroadcastHarnessWithdraw is FundMe_Withdraw_InteractionContract {
    function setTools(IDevOpsTools _tools) external {
        tools = _tools;
    }

    function callDirect(address ca) external {
        FundMe_Withdraw_Interaction(ca);
    }
}

// Expose _before/_after langsung
contract ExposedFund is FundMe_Fund_InteractionContract {
    function callBefore() external {
        _before();
    }

    function callAfter() external {
        _after();
    }
}

contract ExposedWithdraw is FundMe_Withdraw_InteractionContract {
    function callBefore() external {
        _before();
    }

    function callAfter() external {
        _after();
    }
}

contract RevertingDevOpsTools is IDevOpsTools {
    function get_most_recent_deployment(string memory, uint256) external pure override returns (address) {
        revert("no deployment");
    }
}

contract InteractionsScriptTest is Test {
    uint256 constant SEND_VALUE = 0.1 ether;

    FundHarness internal fundHarness;
    WithdrawHarness internal withdrawHarness;
    FundMeStub internal stub;

    function setUp() public {
        fundHarness = new FundHarness();
        withdrawHarness = new WithdrawHarness();
        stub = new FundMeStub();
    }

    function test_fund_core_and_public_are_covered() public {
        deal(address(this), 1 ether);

        fundHarness.callFund{value: SEND_VALUE}(address(stub), SEND_VALUE);
        assertEq(stub.totalReceived(), SEND_VALUE);

        fundHarness.callFundPublic{value: SEND_VALUE}(address(stub));
        assertEq(stub.totalReceived(), 2 * SEND_VALUE);
    }

    function test_withdraw_core_and_public_are_covered() public {
        withdrawHarness.callWithdraw(address(stub));
        withdrawHarness.callWithdrawPublic(address(stub));
        assertEq(stub.withdrawCount(), 2);
    }

    function testFuzz_fund_core(uint96 seed) public {
        deal(address(this), uint256(seed) + SEND_VALUE);
        fundHarness.callFund{value: SEND_VALUE}(address(stub), SEND_VALUE);
        assertEq(stub.totalReceived(), SEND_VALUE);
    }

    function test_run_functions_are_covered() public {
        FakeDevOpsTools fake = new FakeDevOpsTools(address(stub));
        fundHarness.setTools(fake);
        withdrawHarness.setTools(fake);

        deal(address(fundHarness), SEND_VALUE);
        fundHarness.callRun();
        withdrawHarness.callRun();

        assertEq(stub.totalReceived(), SEND_VALUE);
        assertEq(stub.withdrawCount(), 1);
    }

    function test_broadcast_hooks_are_covered() public {
        BroadcastHarnessFund f = new BroadcastHarnessFund();
        BroadcastHarnessWithdraw w = new BroadcastHarnessWithdraw();
        FakeDevOpsTools fake = new FakeDevOpsTools(address(stub));
        f.setTools(fake);
        w.setTools(fake);

        deal(address(f), SEND_VALUE);
        f.callDirect(address(stub));
        w.callDirect(address(stub));
    }

    function test_logs_are_hit() public {
        deal(address(fundHarness), SEND_VALUE);
        deal(address(withdrawHarness), SEND_VALUE);

        fundHarness.callFundPublic(address(stub));
        withdrawHarness.callWithdrawPublic(address(stub));
    }

    function test_run_functions_revert_branch() public {
        RevertingDevOpsTools bad = new RevertingDevOpsTools();
        fundHarness.setTools(bad);
        withdrawHarness.setTools(bad);

        vm.expectRevert();
        fundHarness.callRun();

        vm.expectRevert();
        withdrawHarness.callRun();
    }
}
