// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {
    TokenSpender,
    GenericCaller,
    UpgradeableProxy,
    OracleReader,
    SendWrapper,
    TransferWrapper,
    PaymentProcessor,
    ChildFactory,
    ChildContract,
    SafeERC20Caller,
    IERC20,
    IPriceOracle
} from "src/COC.sol";

/*//////////////////////////////////////////////////////////////
                         TEST HELPERS
//////////////////////////////////////////////////////////////*/

contract MockERC20Bool is IERC20 {
    string public name = "MockBool";
    string public symbol = "MB";
    uint8 public decimals = 18;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    function mint(address to, uint256 amt) external {
        balanceOf[to] += amt;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        require(balanceOf[msg.sender] >= value, "bal");
        unchecked {
            balanceOf[msg.sender] -= value;
        }
        balanceOf[to] += value;
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        require(balanceOf[from] >= value, "bal");
        require(allowance[from][msg.sender] >= value, "allow");
        unchecked {
            allowance[from][msg.sender] -= value;
            balanceOf[from] -= value;
        }
        balanceOf[to] += value;
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        return true;
    }
}

// Non-standard token (no return value on transfer/transferFrom). Mimics USDT-like behavior.
contract MockERC20NoReturn {
    string public name = "MockNoRet";
    string public symbol = "MNR";
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amt) external {
        balanceOf[to] += amt;
    }

    function transfer(address to, uint256 value) external {
        require(balanceOf[msg.sender] >= value, "bal");
        unchecked {
            balanceOf[msg.sender] -= value;
        }
        balanceOf[to] += value;
    }

    function transferFrom(address from, address to, uint256 value) external {
        require(balanceOf[from] >= value, "bal");
        require(allowance[from][msg.sender] >= value, "allow");
        unchecked {
            allowance[from][msg.sender] -= value;
            balanceOf[from] -= value;
        }
        balanceOf[to] += value;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        return true;
    }
}

contract MockOracle is IPriceOracle {
    uint256 public price;

    constructor(uint256 p) {
        price = p;
    }

    function latestPrice() external view returns (uint256) {
        return price;
    }
}

// Receiver that consumes >2300 gas on receive (SSTORE), causing send/transfer to fail
contract GasHogReceiver {
    uint256 public x;

    receive() external payable {
        // SSTORE requires ~20k gas, which exceeds stipend 2300 => send returns false, transfer reverts
        x = block.number;
    }
}

// Malicious receiver to test reentrancy protection in PaymentProcessor
interface IPaymentProcessor {
    function withdraw(uint256) external;
    function deposit() external payable;
}

contract ReentrantReceiver {
    IPaymentProcessor public pp;
    bool public entered;

    constructor(IPaymentProcessor _pp) {
        pp = _pp;
    }

    function attackDepositAndWithdraw() external payable {
        pp.deposit{value: msg.value}();
        pp.withdraw(msg.value);
    }

    receive() external payable {
        if (!entered) {
            entered = true;
            // Re-enter; should fail due to nonReentrant guard
            try pp.withdraw(1) {
                revert("reentrancy not blocked");
            } catch {}
        }
    }
}

/*//////////////////////////////////////////////////////////////
                            PROXY LOGIC
//////////////////////////////////////////////////////////////*/

interface ILogic {
    function set(uint256) external;
    function get() external view returns (uint256);
}

contract LogicV1 is ILogic {
    // Storage will live in the proxy
    uint256 public val; // slot 0

    function set(uint256 v) external {
        val = v;
    }

    function get() external view returns (uint256) {
        return val;
    }
}

contract LogicV2 is ILogic {
    uint256 public val; // must match layout

    function set(uint256 v) external {
        val = v * 2;
    } // changed behavior

    function get() external view returns (uint256) {
        return val;
    }
}

/*//////////////////////////////////////////////////////////////
                               TESTS
//////////////////////////////////////////////////////////////*/

contract COCTest is Test {
    // Mirror ChildFactory.Deployed event for expectEmit matching
    event Deployed(address indexed child, address indexed owner, uint256 x);

    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
    }

    /* ------------------------- 1) High-level interface ------------------------- */
    function test_TokenSpender_spend_succeeds_withBoolToken() public {
        MockERC20Bool t = new MockERC20Bool();
        t.mint(alice, 1_000 ether);

        TokenSpender spender = new TokenSpender();

        // Alice approves spender
        vm.startPrank(alice);
        t.approve(address(spender), 100 ether);
        spender.spend(address(t), alice, bob, 100 ether);
        vm.stopPrank();

        assertEq(t.balanceOf(bob), 100 ether);
    }

    /* ---------------------------- 2) Low-level call ---------------------------- */
    function test_GenericCaller_calls_transfer_via_selector() public {
        MockERC20Bool t = new MockERC20Bool();
        GenericCaller caller = new GenericCaller();

        // GenericCaller akan menjadi msg.sender saat memanggil ERC20.transfer
        t.mint(address(caller), 50 ether);

        bytes memory args = abi.encode(bob, 10 ether);
        caller.callAny(address(t), IERC20.transfer.selector, args);

        assertEq(t.balanceOf(bob), 10 ether);
    }

    /* ----------------------------- 3) Delegatecall ----------------------------- */
    function test_UpgradeableProxy_upgrade_and_state_kept() public {
        LogicV1 impl1 = new LogicV1();
        UpgradeableProxy proxy = new UpgradeableProxy(address(this), address(impl1), "");

        // Interact via interface pointed at proxy
        ILogic P = ILogic(address(proxy));
        P.set(7);
        assertEq(P.get(), 7);

        // Upgrade
        LogicV2 impl2 = new LogicV2();
        proxy.upgradeTo(address(impl2), "");

        // Behavior changed, storage preserved (in proxy)
        P.set(3); // V2 doubles
        assertEq(P.get(), 6);
    }

    /* ------------------------------- 4) Staticcall ----------------------------- */
    function test_OracleReader_reads_price() public {
        MockOracle oracle = new MockOracle(42e8);
        OracleReader reader = new OracleReader();
        uint256 p = reader.readPrice(address(oracle));
        assertEq(p, 42e8);
    }

    /* --------------------- 5) Send wrapper with pull credit -------------------- */
    function test_SendWrapper_send_or_credit_and_withdraw() public {
        SendWrapper w = new SendWrapper();
        GasHogReceiver r = new GasHogReceiver();

        // Using send => should fail due to 2300 gas stipend; amount credited
        w.sendOrCredit{value: 1 ether}(payable(address(r)), 1 ether);
        assertEq(w.failedCredit(address(r)), 1 ether);

        // Receiver pulls later
        uint256 balBefore = address(r).balance;
        vm.prank(address(r));
        w.withdrawCredit();
        assertEq(address(r).balance, balBefore + 1 ether);
        assertEq(w.failedCredit(address(r)), 0);
    }

    /* --------------------------- 6) transfer wrapper --------------------------- */
    function test_TransferWrapper_reverts_to_gashog() public {
        TransferWrapper w = new TransferWrapper();
        GasHogReceiver r = new GasHogReceiver();
        vm.deal(address(this), 1 ether);
        vm.expectRevert();
        w.pay{value: 1 ether}(payable(address(r))); // transfer reverts because receive() needs >2300 gas
    }

    /* ----------------------- 7) call{value:...} with guard --------------------- */
    function test_PaymentProcessor_deposit_and_withdraw_with_guard() public {
        PaymentProcessor pp = new PaymentProcessor();

        // Honest flow
        vm.deal(alice, 2 ether);
        vm.prank(alice);
        pp.deposit{value: 2 ether}();
        assertEq(pp.balances(alice), 2 ether);

        uint256 before = alice.balance;
        vm.prank(alice);
        pp.withdraw(1 ether);
        assertEq(pp.balances(alice), 1 ether);
        assertEq(alice.balance, before + 1 ether);

        // Reentrancy attempt via malicious contract
        ReentrantReceiver attacker = new ReentrantReceiver(IPaymentProcessor(address(pp)));
        vm.deal(address(attacker), 1 ether);
        attacker.attackDepositAndWithdraw();
        assertEq(address(attacker).balance, 1 ether);
    }

    /* ------------------------------- 8) new/deploy ------------------------------ */
    function test_ChildFactory_deploys_child_and_emits() public {
        ChildFactory f = new ChildFactory();

        // We don't know the child address beforehand, so don't check topic1 (child)
        // Check topic2 (owner) and data (x). Emitter must be the factory address.
        vm.expectEmit(false, true, false, true, address(f));
        emit Deployed(address(0), address(this), 7);

        address child = f.deploy(7);
        ChildContract c = ChildContract(payable(child));
        assertEq(c.owner(), address(this));
        assertEq(c.x(), 7);
    }

    /* -------------------------- SafeERC20Caller cases -------------------------- */
    function test_SafeERC20Caller_with_bool_token() public {
        MockERC20Bool t = new MockERC20Bool();
        SafeERC20Caller s = new SafeERC20Caller();

        t.mint(address(s), 5 ether);
        s.safeTransfer(address(t), bob, 2 ether);

        assertEq(t.balanceOf(bob), 2 ether);
    }

    function test_SafeERC20Caller_with_no_return_token() public {
        MockERC20NoReturn t = new MockERC20NoReturn();
        SafeERC20Caller s = new SafeERC20Caller();

        t.mint(address(s), 5 ether);
        s.safeTransfer(address(t), bob, 3 ether);

        assertEq(t.balanceOf(bob), 3 ether);
    }
}
