// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {IERC20} from "../src/Interfaces.sol";
import {SafeTransferLib, UintOps, PublicMath} from "../src/Library.sol";

/* ////////////////////////////////////////////////////////////
//                       M O C K S
//////////////////////////////////////////////////////////// */

contract ERC20StandardMock is IERC20 {
    string public name = "STD";
    string public symbol = "STD";
    uint8 public decimals = 18;

    uint256 private _total;
    mapping(address => uint256) private _bal;
    mapping(address => mapping(address => uint256)) private _allow;

    function mint(address to, uint256 amount) external {
        _total += amount;
        _bal[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function totalSupply() external view returns (uint256) {
        return _total;
    }

    function balanceOf(address a) external view returns (uint256) {
        return _bal[a];
    }

    function allowance(address o, address s) external view returns (uint256) {
        return _allow[o][s];
    }

    function approve(address s, uint256 amount) external returns (bool) {
        _allow[msg.sender][s] = amount;
        emit Approval(msg.sender, s, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(_bal[msg.sender] >= amount, "bal");
        unchecked {
            _bal[msg.sender] -= amount;
            _bal[to] += amount;
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 a = _allow[from][msg.sender];
        require(a >= amount && _bal[from] >= amount, "allow/bal");
        unchecked {
            _allow[from][msg.sender] = a - amount;
            _bal[from] -= amount;
            _bal[to] += amount;
        }
        emit Transfer(from, to, amount);
        return true;
    }
}

// Token non-standar: transfer/transferFrom tidak mengembalikan bool (return data kosong)
contract ERC20NoReturnMock {
    string public name = "NOR";
    string public symbol = "NOR";
    uint8 public decimals = 18;

    uint256 private _total;
    mapping(address => uint256) private _bal;
    mapping(address => mapping(address => uint256)) private _allow;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function mint(address to, uint256 amount) external {
        _total += amount;
        _bal[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function totalSupply() external view returns (uint256) {
        return _total;
    }

    function balanceOf(address a) external view returns (uint256) {
        return _bal[a];
    }

    function allowance(address o, address s) external view returns (uint256) {
        return _allow[o][s];
    }

    function approve(address s, uint256 amount) external {
        _allow[msg.sender][s] = amount;
        emit Approval(msg.sender, s, amount);
    }

    // ⚠️ tidak return bool
    function transfer(address to, uint256 amount) external {
        require(_bal[msg.sender] >= amount, "bal");
        unchecked {
            _bal[msg.sender] -= amount;
            _bal[to] += amount;
        }
        emit Transfer(msg.sender, to, amount);
    }

    // ⚠️ tidak return bool
    function transferFrom(address from, address to, uint256 amount) external {
        uint256 a = _allow[from][msg.sender];
        require(a >= amount && _bal[from] >= amount, "allow/bal");
        unchecked {
            _allow[from][msg.sender] = a - amount;
            _bal[from] -= amount;
            _bal[to] += amount;
        }
        emit Transfer(from, to, amount);
    }
}

// Penerima ETH sederhana
contract PayableSink {
    event Received(address indexed from, uint256 amount);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

// Penerima ETH yang selalu revert (untuk test bubble-up reason)
contract RevertingSink {
    error Nope();

    receive() external payable {
        revert Nope();
    }
}

/* ////////////////////////////////////////////////////////////
//                   U S E R   C O N T R A C T
//////////////////////////////////////////////////////////// */

contract LibUser {
    using UintOps for uint256;

    function clampEven(uint256 x, uint256 lo, uint256 hi) external pure returns (bool even, uint256 clamped) {
        return (x.isEven(), x.clamp(lo, hi));
    }

    // SafeTransferLib wrappers
    function sendETH(address to, uint256 amount) external payable {
        SafeTransferLib.safeTransferETH(to, amount);
    }

    function safeSendToken(IERC20 t, address to, uint256 amount) external {
        SafeTransferLib.safeTransfer(t, to, amount);
    }

    function safeSendTokenFrom(IERC20 t, address from, address to, uint256 amount) external {
        SafeTransferLib.safeTransferFrom(t, from, to, amount);
    }

    // PublicMath (external library): panggilan memerlukan deploy+link
    function avg(uint256 a, uint256 b) external pure returns (uint256) {
        return PublicMath.mulDiv(a + b, 1, 2);
    }

    function sumArr(uint256[] memory arr) external pure returns (uint256) {
        return PublicMath.sum(arr);
    }

    // Terima ETH untuk memudahkan funding test
    receive() external payable {}
}

/* ////////////////////////////////////////////////////////////
//                           T E S T S
//////////////////////////////////////////////////////////// */

contract LibraryTest is Test {
    LibUser user;
    PayableSink sink;
    RevertingSink badSink;
    ERC20StandardMock std;
    ERC20NoReturnMock nor;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        user = new LibUser();
        sink = new PayableSink();
        badSink = new RevertingSink();
        std = new ERC20StandardMock();
        nor = new ERC20NoReturnMock();

        // Seed ETH
        vm.deal(address(user), 100 ether);
        vm.deal(alice, 50 ether);

        // Seed tokens
        std.mint(address(user), 1_000 ether);
        std.mint(alice, 500 ether);

        nor.mint(address(user), 1_000 ether);
        nor.mint(alice, 500 ether);

        // Approvals untuk transferFrom case
        vm.prank(alice);
        std.approve(address(user), type(uint256).max);
        vm.prank(alice);
        nor.approve(address(user), type(uint256).max);
    }

    /* ----------------------- UintOps ----------------------- */

    function test_UintOps_IsEven_Clamp_SatAdd() public view {
        (bool even2, uint256 c1) = user.clampEven(2, 10, 20);
        assertTrue(even2);
        assertEq(c1, 10);

        (bool even3, uint256 c2) = user.clampEven(3, 0, 2);
        assertFalse(even3);
        assertEq(c2, 2);

        // saturatingAdd langsung via library (internal)
        uint256 sat = UintOps.saturatingAdd(type(uint256).max, 1);
        assertEq(sat, type(uint256).max);
    }

    /* -------------------- SafeTransferLib ------------------ */

    function test_SafeTransferETH_SendsValue() public {
        uint256 beforeBal = address(sink).balance;

        vm.prank(address(user));
        user.sendETH{value: 1 ether}(address(sink), 1 ether);

        assertEq(address(sink).balance, beforeBal + 1 ether);
    }

    function test_SafeTransferETH_BubblesReason() public {
        vm.prank(address(user));
        // Revert reason bubbling dari RevertingSink.Nope()
        vm.expectRevert(RevertingSink.Nope.selector);
        user.sendETH{value: 1}(address(badSink), 1);
    }

    function test_SafeTransfer_Token_Standard() public {
        // user → bob (STD)
        uint256 beforeUser = std.balanceOf(address(user));
        uint256 beforeBob = std.balanceOf(bob);

        vm.prank(address(user));
        user.safeSendToken(IERC20(address(std)), bob, 10 ether);

        assertEq(std.balanceOf(address(user)), beforeUser - 10 ether);
        assertEq(std.balanceOf(bob), beforeBob + 10 ether);
    }

    function test_SafeTransfer_Token_NoReturn() public {
        // user → bob (NOR) token yang tidak return bool
        uint256 beforeUser = nor.balanceOf(address(user));
        uint256 beforeBob = nor.balanceOf(bob);

        vm.prank(address(user));
        user.safeSendToken(IERC20(address(nor)), bob, 7 ether);

        assertEq(nor.balanceOf(address(user)), beforeUser - 7 ether);
        assertEq(nor.balanceOf(bob), beforeBob + 7 ether);
    }

    function test_SafeTransferFrom_Token_Standard() public {
        // user menarik dari alice → bob
        uint256 beforeAlice = std.balanceOf(alice);
        uint256 beforeBob = std.balanceOf(bob);

        vm.prank(address(user));
        user.safeSendTokenFrom(IERC20(address(std)), alice, bob, 3 ether);

        assertEq(std.balanceOf(alice), beforeAlice - 3 ether);
        assertEq(std.balanceOf(bob), beforeBob + 3 ether);
    }

    function test_SafeTransferFrom_Token_NoReturn() public {
        uint256 beforeAlice = nor.balanceOf(alice);
        uint256 beforeBob = nor.balanceOf(bob);

        vm.prank(address(user));
        user.safeSendTokenFrom(IERC20(address(nor)), alice, bob, 5 ether);

        assertEq(nor.balanceOf(alice), beforeAlice - 5 ether);
        assertEq(nor.balanceOf(bob), beforeBob + 5 ether);
    }

    /* ---------------------- PublicMath --------------------- */

    function test_PublicMath_mulDiv_and_sum() public view {
        // rata-rata
        uint256 avg = user.avg(7, 9); // (7+9)/2 = 8
        assertEq(avg, 8);

        uint256[] memory arr = new uint256[](4);
        arr[0] = 1;
        arr[1] = 2;
        arr[2] = 3;
        arr[3] = 4;
        uint256 s = user.sumArr(arr);
        assertEq(s, 10);
    }
}
