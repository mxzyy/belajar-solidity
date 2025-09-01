// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {ImportExample} from "../src/Import.sol";
import {IERC20} from "../src/Interfaces.sol";
import {NotAuthorized} from "../src/Types.sol";
import {Ownable} from "../src/Ownable.sol";

/* ---------------------------------------------------------- */
/*                         Mocks                               */
/* ---------------------------------------------------------- */

contract MockERC20 is IERC20 {
    string public name = "Mock";
    string public symbol = "MOCK";
    uint8 public decimals = 18;

    uint256 private _totalSupply;
    mapping(address => uint256) private _bal;

    function mint(address to, uint256 amount) external {
        _totalSupply += amount;
        _bal[to] += amount;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _bal[account];
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        address from = msg.sender;
        uint256 bal = _bal[from];
        require(bal >= amount, "ERC20: balance too low");
        unchecked {
            _bal[from] = bal - amount;
            _bal[to] += amount;
        }
        return true;
    }
}

/* ---------------------------------------------------------- */
/*                      Test Contract                          */
/* ---------------------------------------------------------- */

contract ImportTest is Test {
    // redeclare event untuk expectEmit (event aslinya didefinisikan di abstract contract Events)
    event UserRegistered(address indexed user, uint256 timestamp);

    ImportExample internal imp;
    MockERC20 internal token;

    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function setUp() public {
        token = new MockERC20();
        imp = new ImportExample(address(token));

        // Siapkan saldo token di kontrak agar bisa reward
        token.mint(address(imp), 1_000 ether);
    }

    /* ------------------------------------------------------ */
    /*                      register()                         */
    /* ------------------------------------------------------ */

    function test_Register_EmitsEvent_AndStoresUser() public {
        uint256 init = 2 ether; // even & > 0

        vm.prank(alice);
        // Cek hanya topic indexed address; data (timestamp) tidak dicek
        vm.expectEmit(true, false, false, false, address(imp));
        emit UserRegistered(alice, 0);
        imp.register(init);

        // Verifikasi state
        (bool okAcc, uint256 bal) = _userOf(alice);
        assertTrue(okAcc, "user.account != alice");
        assertEq(bal, init, "stored balance mismatch");
    }

    function test_Register_Reverts_OnZero() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(NotAuthorized.selector, alice));
        imp.register(0);
    }

    function test_Register_Reverts_OnOdd() public {
        vm.prank(alice);
        // 3 is odd → isEven == false → NotAuthorized(alice)
        vm.expectRevert(abi.encodeWithSelector(NotAuthorized.selector, alice));
        imp.register(3);
    }

    /* ------------------------------------------------------ */
    /*                       reward()                          */
    /* ------------------------------------------------------ */

    function test_Reward_OnlyOwner() public {
        // Panggil sebagai non-owner
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Ownable.NotOwner.selector));
        imp.reward(alice, 10 ether);
    }

    function test_Reward_TransfersToken_AndAccumulatesUserBalance() public {
        // Owner memanggil reward
        uint256 beforeContract = IERC20(address(token)).balanceOf(address(imp));
        uint256 amount = 10 ether;

        imp.reward(alice, amount);

        // Token berpindah
        assertEq(IERC20(address(token)).balanceOf(alice), amount, "alice token not received");
        assertEq(IERC20(address(token)).balanceOf(address(imp)), beforeContract - amount, "contract token not deducted");

        // Balance user bertambah (awal 0, jadi 10 ether)
        (bool okAcc, uint256 bal) = _userOf(alice);
        assertTrue(okAcc, "user.account != alice after reward");
        assertEq(bal, amount, "user balance not accumulated correctly");

        // Tambah lagi memastikan akumulasi
        imp.reward(alice, amount);
        (, bal) = _userOf(alice);
        assertEq(bal, 2 * amount, "user balance second accumulation failed");
    }

    /* ------------------------------------------------------ */
    /*                   getUserStatus()                       */
    /* ------------------------------------------------------ */

    function test_GetUserStatus_Works() public {
        // default user (0 balance) → Pending
        assertEq(uint256(imp.getUserStatus(bob)), uint256(0), "Pending expected");

        // register kecil → Failed (<= 100 ether)
        vm.prank(alice);
        imp.register(2 ether);
        assertEq(uint256(imp.getUserStatus(alice)), uint256(2), "Failed expected");

        // reward besar → Success (> 100 ether)
        imp.reward(alice, 200 ether);
        assertEq(uint256(imp.getUserStatus(alice)), uint256(1), "Success expected");
    }

    /* ------------------------------------------------------ */
    /*                       helpers                           */
    /* ------------------------------------------------------ */

    // Ambil (account == user) & balance dari mapping users
    function _userOf(address who) internal view returns (bool isAccount, uint256 bal) {
        // users is (address account, uint256 balance)
        (address account, uint256 balance) = imp.users(who);
        return (account == who, balance);
    }
}
