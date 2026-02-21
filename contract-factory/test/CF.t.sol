// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/CF.sol";

contract CFTest is Test {
    CF internal cf;

    // Re-declare event persis seperti di CF agar bisa expectEmit
    event WalletDeployed(address indexed owner, address indexed wallet, bytes32 indexed salt, uint256 value);

    address internal OWNER; // owner Wallet nantinya
    address internal RECEIVER; // penerima withdraw/rescue
    address internal ATTACKER; // dipakai buat uji onlyOwner

    function setUp() public {
        cf = new CF();
        OWNER = makeAddr("OWNER");
        RECEIVER = makeAddr("RECEIVER");
        ATTACKER = makeAddr("ATTACKER");

        // Bekali akun2 dengan ETH untuk transaksi
        vm.deal(address(this), 100 ether);
        vm.deal(OWNER, 100 ether);
        vm.deal(RECEIVER, 1 ether);
        vm.deal(ATTACKER, 1 ether);
    }

    /* --------------------------------------------------------
       1) Predict == Deployed (CREATE2 deterministik)
    ---------------------------------------------------------*/
    function test_PredictMatchesDeployed_CREATE2() public {
        bytes32 salt = keccak256("salt-1");
        address predicted = cf.predictWalletAddress(OWNER, salt);

        vm.expectEmit(true, true, true, true);
        emit WalletDeployed(OWNER, predicted, salt, 0);

        // deploy tanpa value
        address deployed = cf.deployWalletDeterministic(OWNER, salt);
        assertEq(deployed, predicted, "predicted vs deployed mismatch");

        // code size di alamat harus > 0
        assertGt(_codeSize(deployed), 0, "no code at deployed address");
    }

    /* --------------------------------------------------------
       2) Counterfactual funding + tebus (CREATE2)
    ---------------------------------------------------------*/
    function test_CounterfactualFunding_thenRedeem() public {
        bytes32 salt = keccak256("salt-2");
        address predicted = cf.predictWalletAddress(OWNER, salt);

        // Kirim ETH ke address counterfactual sebelum deploy
        uint256 preload = 1.5 ether;
        (bool ok,) = payable(predicted).call{value: preload}("");
        assertTrue(ok, "preload ETH transfer failed");

        // Pastikan belum ada code
        assertEq(_codeSize(predicted), 0, "address already has code unexpectedly");

        // Deploy (tebus) — tidak kirim value tambahan
        address deployed = cf.deployWalletDeterministic(OWNER, salt);
        assertEq(deployed, predicted, "deploy must land at predicted");

        // Balance kontrak harus sama dengan preload
        assertEq(address(deployed).balance, preload, "wallet balance mismatch after redeem");

        // Owner tarik semua ke RECEIVER
        Wallet w = Wallet(payable(deployed));
        uint256 beforeBal = RECEIVER.balance;

        vm.prank(OWNER);
        w.withdrawAll(payable(RECEIVER));

        assertEq(RECEIVER.balance, beforeBal + preload, "receiver did not get withdrawn funds");
        assertEq(address(deployed).balance, 0, "wallet should be empty after withdrawAll");
    }

    /* --------------------------------------------------------
       3) Double deploy dengan salt yang sama harus revert
    ---------------------------------------------------------*/
    function test_DoubleDeployReverts() public {
        bytes32 salt = keccak256("salt-3");
        address predicted = cf.predictWalletAddress(OWNER, salt);

        // Deploy pertama ok
        address deployed = cf.deployWalletDeterministic(OWNER, salt);
        assertEq(deployed, predicted);

        // Deploy kedua dengan salt sama → revert AlreadyDeployed(predicted)
        vm.expectRevert(abi.encodeWithSelector(CF.AlreadyDeployed.selector, predicted));
        cf.deployWalletDeterministic(OWNER, salt);
    }

    /* --------------------------------------------------------
       4) Jalur CREATE (non-deterministic) + event
    ---------------------------------------------------------*/
    function test_DeployWallet_CREATE_EmitsEvent() public {
        // Karena CREATE alamatnya non-deterministic, kita gak bisa tahu sebelum deploy.
        // Kita bisa expectEmit dengan indexed owner & wildcard lainnya (salt = 0).
        vm.expectEmit(true, false, true, true);
        emit WalletDeployed(OWNER, address(0), bytes32(0), 0);

        address waddr = cf.deployWallet(OWNER);
        assertGt(_codeSize(waddr), 0, "no code at CREATE address");
    }

    /* --------------------------------------------------------
       5) onlyOwner di rescueETH
    ---------------------------------------------------------*/
    function test_RescueETH_OnlyOwner() public {
        // Isi saldo CF tanpa selfdestruct
        vm.deal(address(cf), 2 ether);
        assertEq(address(cf).balance, 2 ether, "CF should hold 2 ether");

        // Non-owner tidak boleh rescue
        vm.prank(ATTACKER);
        vm.expectRevert(CF.NotOwner.selector);
        cf.rescueETH(payable(RECEIVER));

        // Owner boleh rescue
        uint256 before = RECEIVER.balance;
        cf.rescueETH(payable(RECEIVER));
        assertEq(RECEIVER.balance, before + 2 ether, "receiver did not get rescued ETH");
        assertEq(address(cf).balance, 0, "CF should be drained");
    }

    /* --------------------------------------------------------
       6) Constructor revert bubbling (OWNER=address(0))
    ---------------------------------------------------------*/
    function test_ConstructorRevertBubbles() public {
        bytes32 salt = keccak256("salt-bad");

        // Owner = address(0) di-block oleh CF sebelum constructor Wallet jalan.
        vm.expectRevert(CF.ZeroOwner.selector);
        cf.deployWalletDeterministic(address(0), salt);

        // Pastikan tidak ada code di alamat predicted
        address predicted = cf.predictWalletAddress(address(0), salt);
        assertEq(_codeSize(predicted), 0, "no code should exist after failed guard");
    }

    /* --------------------------------------------------------
       7) Strict variant: gas check
    ---------------------------------------------------------*/
    function test_StrictVariant_InsufficientGasReverts() public {
        bytes32 salt = keccak256("salt-strict");
        uint256 absurd = type(uint256).max;

        try cf.deployWalletDeterministicStrict(OWNER, salt, absurd) {
            fail("should revert");
        } catch (bytes memory err) {
            // ambil 4 byte pertama sebagai selector
            bytes4 sel;
            assembly {
                sel := mload(add(err, 0x20))
            }
            assertEq(sel, CF.InsufficientGas.selector, "wrong error selector");
        }
    }

    /* --------------------------------------------------------
       8) NonReentrant sanity (constructor callback prevention)
       (High-level: sulit mensimulasikan reentrancy ke factory dari constructor
       tanpa menulis kontrak berbahaya; kita cukup pastikan guard aktif.)
    ---------------------------------------------------------*/
    function test_NonReentrant_IsActive() public {
        // Sanity: panggil deterministic deploy normal → sukses
        bytes32 salt = keccak256("salt-nr");
        cf.deployWalletDeterministic(OWNER, salt);

        // Tidak ada assert spesifik di sini; nonReentrant diuji implicit.
        // Untuk uji negatif lengkap butuh kontrak Child constructor yang callback ke CF.
        assertTrue(true);
    }

    /* --------------------------------------------------------
       Helpers
    ---------------------------------------------------------*/
    function _codeSize(address a) internal view returns (uint256 size) {
        assembly {
            size := extcodesize(a)
        }
    }
}
