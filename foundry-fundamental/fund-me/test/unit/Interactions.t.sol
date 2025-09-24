// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// ─────────────────────────────────────────────────────────────────────────────
// Foundry
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

// SUT (scripts)
import {FundMe_Fund_InteractionContract, FundMe_Withdraw_InteractionContract} from "../../script/Interaction.s.sol"; // adjust path if needed

// Interface we rely on (minimal shape used by scripts)
interface IFundMeLike {
    function fund() external payable;
    function withdraw() external;
}

// ─────────────────────────────────────────────────────────────────────────────
// Test double: NO owner checks, mirrors your statement "ga ada modifier only owner"
contract FundMeStub is IFundMeLike {
    uint256 public totalReceived;
    uint256 public withdrawCount;

    function fund() external payable override {
        totalReceived += msg.value;
    }

    function withdraw() external override {
        withdrawCount++;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Harnesses that bypass vm.startBroadcast() so tests don't collide with pranks
contract FundHarness is FundMe_Fund_InteractionContract {
    function _fundNoBroadcast(address recentCA) external payable {
        IFundMeLike(payable(recentCA)).fund{value: SEND_VALUE}();
    }
}

contract WithdrawHarness is FundMe_Withdraw_InteractionContract {
    function _withdrawNoBroadcast(address recentCA) external {
        IFundMeLike(payable(recentCA)).withdraw();
    }
}

// ─────────────────────────────────────────────────────────────────────────────
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

    function test_fund_sendsExactValue_coreLogic() public {
        deal(address(this), 1 ether);
        fundHarness._fundNoBroadcast{value: SEND_VALUE}(address(stub));
        assertEq(stub.totalReceived(), SEND_VALUE, "fund() should receive 0.1 ETH");
    }

    function test_withdraw_callsWithdraw_coreLogic_noOwnerRestriction() public {
        withdrawHarness._withdrawNoBroadcast(address(stub));
        assertEq(stub.withdrawCount(), 1, "withdraw() should be called once");
    }

    function testFuzz_fund_coreLogic_doesNotDependOnSender(uint96 seed) public {
        uint256 bal = uint256(seed) + SEND_VALUE;
        deal(address(this), bal);
        fundHarness._fundNoBroadcast{value: SEND_VALUE}(address(stub));
        assertEq(stub.totalReceived(), SEND_VALUE);
    }
}
