// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DGProxy, DGv1, IDGv1} from "../src/DG.sol";

/* -------------------------------------------------------------------------- */
/*                             Test Helper: DGv2                              */
/* -------------------------------------------------------------------------- */
/**
 * DGv2 mempertahankan layout DGv1 (owner, myVar) lalu menambah fitur baru.
 * Tambah reinitializer V2 (once-only) agar bisa dipanggil lewat upgradeToAndCall
 * oleh ADMIN proxy, bukan owner logic.
 */
contract DGv2 is DGv1 {
    bool private _v2Inited;

    function version() external pure returns (uint256) {
        return 2;
    }

    function bump(uint256 by) external onlyOwner {
        myVar += by;
    }

    /// Reinit khusus V2: dapat dipanggil sekali saat upgrade (oleh admin proxy).
    function reinitV2(uint256 newVal) external {
        if (_v2Inited) revert AlreadyInitialized();
        _v2Inited = true;
        myVar = newVal;
    }
}

/* -------------------------------------------------------------------------- */
/*                                   TESTS                                    */
/* -------------------------------------------------------------------------- */

/// @dev Interface view ke DGv1 di alamat PROXY + deklarasi custom errors untuk selector yang dipakai test.
interface IDGv1View is IDGv1 {
    // View getters pada logic (disimpan di storage proxy)
    function owner() external view returns (address);
    function myVar() external view returns (uint256);

    // Tambahkan error yang dipakai test agar bisa direferensikan sebagai IDGv1View.<Error>.selector
    error NotAdmin();
    error ImplIsNotContract();
}

interface IDGv2View {
    function version() external view returns (uint256);
    function bump(uint256 by) external;
    function reinitV2(uint256 newVal) external;
}

contract DGTest is Test {
    address internal deployer;
    address internal admin;
    address internal ownerUser;

    DGv1 internal implV1;
    DGProxy internal proxy;

    // Cast proxy address agar ABI logic bisa dipakai saat call
    IDGv1View internal DG; // V1 view/interface pada alamat proxy

    function setUp() public {
        deployer = address(0xDEAD);
        admin = address(0xA11CE);
        ownerUser = address(0xB0B);

        vm.deal(deployer, 100 ether);
        vm.deal(admin, 100 ether);
        vm.deal(ownerUser, 100 ether);

        // Deploy implementation V1
        vm.prank(deployer);
        implV1 = new DGv1();

        // Siapkan init data: initialize(owner, initialVar)
        bytes memory initData = abi.encodeWithSelector(IDGv1.initialize.selector, ownerUser, uint256(777));

        // Deploy proxy dengan admin & init sekali jalan
        vm.prank(deployer);
        proxy = new DGProxy(address(implV1), admin, initData);

        // Casting proxy ke ABI logic V1 (interaksi user selalu ke alamat proxy)
        DG = IDGv1View(address(proxy));
    }

    /* --------------------------------- Happy --------------------------------- */

    function test_InitState_InitializedViaConstructor() public view {
        assertEq(DG.owner(), ownerUser, "owner must be set via initialize");
        assertEq(DG.myVar(), 777, "myVar must be initialized");
    }

    function test_OnlyOwner_CanSetData() public {
        // Non-owner ditolak
        vm.expectRevert(DGv1.NotOwner.selector);
        DG.setData(123);

        // Owner sukses
        vm.prank(ownerUser);
        DG.setData(123);
        assertEq(DG.myVar(), 123, "myVar updated by owner");
    }

    function test_AdminBlockedFromFallback_ButCanUseAdminFns() public {
        // Admin *boleh* manggil fungsi admin() di proxy (onlyAdmin)
        vm.prank(admin);
        (bool ok, bytes memory ret) = address(proxy).call(abi.encodeWithSignature("admin()"));
        assertTrue(ok, "admin() callable by admin");
        address gotAdmin = abi.decode(ret, (address));
        assertEq(gotAdmin, admin, "admin() returns correct admin");

        // Admin *TIDAK BOLEH* masuk fallback/logic (Transparent Proxy)
        vm.prank(admin);
        vm.expectRevert(IDGv1View.NotAdmin.selector); // pakai selector dari interface
        DG.setData(42); // ini akan masuk fallback -> revert NotAdmin
    }

    function test_NonAdmin_CannotCallAdminFns() public {
        // Non-admin memanggil admin() → revert NotAdmin
        vm.prank(ownerUser);
        vm.expectRevert(IDGv1View.NotAdmin.selector);
        address(proxy).call(abi.encodeWithSignature("admin()"));

        // Non-admin memanggil implementation() → revert NotAdmin
        vm.prank(ownerUser);
        vm.expectRevert(IDGv1View.NotAdmin.selector);
        address(proxy).call(abi.encodeWithSignature("implementation()"));
    }

    /* -------------------------------- Upgrade -------------------------------- */

    function test_UpgradeTo_V2_AndUseNewFunction() public {
        // Deploy V2
        vm.prank(deployer);
        DGv2 implV2 = new DGv2();

        // Upgrade ke V2 oleh admin
        vm.prank(admin);
        (bool ok,) = address(proxy).call(abi.encodeWithSignature("upgradeTo(address)", address(implV2)));
        assertTrue(ok, "upgradeTo should succeed");

        // Interaksi via proxy dengan ABI V2
        IDGv2View DGv2Iface = IDGv2View(address(proxy));

        // Owner & state tetap
        assertEq(DG.owner(), ownerUser, "owner must persist across upgrades");
        assertEq(DG.myVar(), 777, "myVar must persist across upgrades");

        // Fitur baru tersedia
        assertEq(DGv2Iface.version(), 2, "DGv2.version()==2");

        // Owner bisa pakai fungsi baru
        vm.prank(ownerUser);
        DGv2Iface.bump(10);
        assertEq(DG.myVar(), 787, "myVar bumped by 10");
    }

    function test_UpgradeToAndCall_V2_WithReinitHook() public {
        // Deploy V2
        vm.prank(deployer);
        DGv2 implV2 = new DGv2();

        // Admin melakukan upgrade + panggil reinitV2(999) (once-only, tanpa onlyOwner)
        bytes memory hook = abi.encodeWithSelector(IDGv2View.reinitV2.selector, uint256(999));

        vm.prank(admin);
        (bool ok,) =
            address(proxy).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(implV2), hook));
        assertTrue(ok, "upgradeToAndCall should succeed");

        assertEq(DG.myVar(), 999, "myVar set during v2 reinit hook");
    }

    function test_Upgrade_RevertIfImplNotContract() public {
        // alamat EOA (bukan kontrak) → code.length == 0
        address notAContract = address(0x12345);

        vm.prank(admin);
        vm.expectRevert(IDGv1View.ImplIsNotContract.selector);
        address(proxy).call(abi.encodeWithSignature("upgradeTo(address)", notAContract));
    }

    function test_NonAdmin_CannotUpgrade() public {
        vm.prank(deployer);
        DGv2 implV2 = new DGv2();

        vm.prank(ownerUser);
        vm.expectRevert(IDGv1View.NotAdmin.selector);
        address(proxy).call(abi.encodeWithSignature("upgradeTo(address)", address(implV2)));
    }

    function test_ChangeAdmin_ThenNewAdminCanUpgrade() public {
        // Ganti admin → newAdmin
        address newAdmin = address(0xADAD);
        vm.deal(newAdmin, 10 ether);

        vm.prank(admin);
        (bool ok1,) = address(proxy).call(abi.encodeWithSignature("changeAdmin(address)", newAdmin));
        assertTrue(ok1, "changeAdmin should succeed");

        // Pastikan admin() = newAdmin
        vm.prank(newAdmin);
        (bool ok2, bytes memory ret) = address(proxy).call(abi.encodeWithSignature("admin()"));
        assertTrue(ok2, "admin() callable by new admin");
        assertEq(abi.decode(ret, (address)), newAdmin, "admin should be newAdmin");

        // New admin bisa upgrade
        vm.prank(deployer);
        DGv2 implV2 = new DGv2();

        vm.prank(newAdmin);
        (bool ok3,) = address(proxy).call(abi.encodeWithSignature("upgradeTo(address)", address(implV2)));
        assertTrue(ok3, "new admin can upgrade");
    }
}
