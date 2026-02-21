// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/**
 * ---------------------------------------------------------------------------
 * DG Transparent Upgradeable Proxy (EIP-1967) + Logic V1
 * ---------------------------------------------------------------------------
 * - Pola: Transparent Proxy (alamat implementasi & admin di slot EIP-1967).
 * - Admin hanya boleh meng-upgrade / ganti admin.
 * - Seluruh panggilan user => fallback => delegatecall ke implementation.
 * - Logic V1 punya "initialize" (bukan constructor) + contoh fungsi setData.
 *
 * CATATAN PENTING:
 * - "Admin" TIDAK bisa memanggil fungsi logic melalui proxy (diblokir),
 *   gunakan akun lain (owner) untuk berinteraksi dengan logic.
 * - "Owner" disimpan di storage logic (yang sebenarnya tersimpan di PROXY).
 * - Saat upgrade, JAGA KONSISTENSI LAYOUT STORAGE logic antars versi.
 * ---------------------------------------------------------------------------
 */

/// @dev Interface minimal untuk memudahkan encode selector saat init/upgrade.
interface IDGv1 {
    function initialize(address _owner, uint256 _initialVar) external;
    function setData(uint256 _data) external;
}

/* ============================ CUSTOM ERRORS ============================ */

error NotAdmin(); // Dipanggil saat non-admin menjalankan fungsi admin.
error ImplIsNotContract(); // Alamat implementasi bukan kontrak (code.length == 0).
error DelegateCallFailed(); // delegatecall gagal (ok == false).

/* ============================ DG PROXY (EIP-1967) ============================ */
/**
 * @title DGProxy
 * @notice Transparent proxy yang menyimpan alamat implementasi & admin di slot EIP-1967.
 *         Semua panggilan (kecuali fungsi admin) akan didelegasikan ke implementation.
 */
contract DGProxy {
    /**
     * EIP-1967 Slots:
     * - IMPLEMENTATION slot = keccak256("eip1967.proxy.implementation") - 1
     * - ADMIN slot          = keccak256("eip1967.proxy.admin") - 1
     *
     * Kenapa pakai slot "ajaib" ini?
     * - Menghindari tabrakan (collision) dengan storage milik logic.
     * - Standar industri; tooling & auditor sudah familiar.
     */
    bytes32 private constant _IMPL_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /* --------------------------------- Events -------------------------------- */

    /// @notice Tercatat setiap kali admin diganti.
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    /// @notice Tercatat setiap kali implementation di-upgrade.
    event Upgraded(address indexed implementation);

    /* -------------------------------- Modifiers ------------------------------- */

    /// @dev Batasi fungsi tertentu untuk admin saja.
    modifier onlyAdmin() {
        if (msg.sender != _getAdmin()) revert NotAdmin();
        _;
    }

    /* ------------------------------ Konstruktor ------------------------------ */
    /**
     * @param impl_   Alamat kontrak logic (implementation) awal.
     * @param admin_  Admin proxy (pengelola upgrade).
     * @param initCalldata  Data panggilan untuk inisialisasi (dipanggil via delegatecall).
     *
     * Rekomendasi:
     * - Set admin = kontrak "ProxyAdmin" (jika ingin pola multi-proxy) atau EOA devops.
     * - Isi initCalldata = abi.encodeWithSelector(IDGv1.initialize.selector, owner, initialVar)
     *   agar storage logic terinisialisasi dalam 1 tx.
     */
    constructor(address impl_, address admin_, bytes memory initCalldata) payable {
        _setAdmin(admin_);
        _upgradeTo(impl_);
        if (initCalldata.length > 0) {
            (bool ok,) = impl_.delegatecall(initCalldata);
            if (!ok) revert DelegateCallFailed();
        }
    }

    /* --------------------------- Fungsi ADMIN (EOA) -------------------------- */

    /// @notice Ganti admin proxy.
    function changeAdmin(address newAdmin) external onlyAdmin {
        _setAdmin(newAdmin);
    }

    /// @notice Upgrade ke implementasi baru.
    function upgradeTo(address newImplementation) external onlyAdmin {
        _upgradeTo(newImplementation);
    }

    /// @notice Upgrade + langsung panggil fungsi init/upgrade hook di implementasi baru.
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable onlyAdmin {
        _upgradeTo(newImplementation);
        (bool ok,) = newImplementation.delegatecall(data);
        if (!ok) revert DelegateCallFailed();
    }

    /* -------------------------- View untuk ADMIN saja ------------------------- */
    /// @notice TAMPILKAN admin saat ini. Hanya bisa dipanggil oleh admin (gaya Transparent Proxy OZ).
    function admin() external view onlyAdmin returns (address) {
        return _getAdmin();
    }

    /// @notice TAMPILKAN implementation saat ini. Hanya bisa dipanggil oleh admin.
    function implementation() external view onlyAdmin returns (address) {
        return _getImplementation();
    }

    /* ------------------------------- Fallback --------------------------------- */
    /**
     * @dev Transparent Proxy rule:
     * - ADMIN TIDAK BOLEH masuk ke fallback (untuk menghindari konflik fungsi).
     * - Hanya non-admin (user/aplikasi) yang diteruskan ke implementation.
     */
    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    function _fallback() internal {
        // Blokir admin agar tidak tak sengaja mengeksekusi logic via proxy.
        if (msg.sender == _getAdmin()) revert NotAdmin();
        _delegate(_getImplementation());
    }

    /* ----------------------------- Internal utils ---------------------------- */

    function _delegate(address impl_) internal {
        assembly {
            // Copy calldata ke memori (offset 0)
            calldatacopy(0, 0, calldatasize())
            // Delegate ke impl_
            let result := delegatecall(gas(), impl_, 0, calldatasize(), 0, 0)
            // Copy returndata ke memori (offset 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    function _getImplementation() internal view returns (address impl_) {
        bytes32 slot = _IMPL_SLOT;
        assembly {
            impl_ := sload(slot)
        }
    }

    function _getAdmin() internal view returns (address admin_) {
        bytes32 slot = _ADMIN_SLOT;
        assembly {
            admin_ := sload(slot)
        }
    }

    function _setAdmin(address newAdmin) internal {
        require(newAdmin != address(0), "admin=0");
        address prev = _getAdmin();
        bytes32 slot = _ADMIN_SLOT;
        assembly {
            sstore(slot, newAdmin)
        }
        emit AdminChanged(prev, newAdmin);
    }

    function _upgradeTo(address newImplementation) internal {
        if (newImplementation.code.length == 0) revert ImplIsNotContract();
        bytes32 slot = _IMPL_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
        emit Upgraded(newImplementation);
    }
}

/* =============================== DG LOGIC V1 =============================== */
/**
 * @title DGv1 (Logic)
 * @notice Kontrak implementasi yang menjalankan logika bisnis.
 *         - TIDAK menyimpan admin; admin ada di proxy.
 *         - Gunakan "initialize" alih-alih constructor (constructor tidak dieksekusi via proxy).
 *         - Jaga kompatibilitas storage saat upgrade (JANGAN ubah urutan/tipe).
 */
contract DGv1 is IDGv1 {
    /* ------------------------------ STORAGE LAYOUT ------------------------------ *
     * Seluruh storage ini disimpan di STORAGE PROXY (karena delegatecall).
     * Pastikan urutan/tipe TIDAK BERUBAH antar versi (upgrade-safe).
     * Tambahkan variabel baru HANYA di akhir.
     * --------------------------------------------------------------------------- */

    /// @notice Pemilik logika (bukan admin proxy). Mengelola fitur bisnis (bukan upgrade).
    address public owner; // slot 0

    /// @notice Contoh state: angka yang bisa diubah owner.
    uint256 public myVar; // slot 1

    /* --------------------------------- Events --------------------------------- */
    event Initialized(address indexed owner, uint256 initialVar);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event MyVarUpdated(uint256 oldValue, uint256 newValue);

    /* -------------------------------- Errors ---------------------------------- */
    error AlreadyInitialized();
    error NotOwner();
    error NewOwnerIsZero();

    /* ------------------------------- Modifiers -------------------------------- */
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /* ------------------------------ Initializer ------------------------------- */
    /**
     * @notice Panggil sekali melalui proxy (lewat constructor proxy atau upgradeToAndCall).
     *         - Set owner
     *         - Set nilai awal myVar
     */
    function initialize(address _owner, uint256 _initialVar) external {
        // Proteksi dari re-init
        if (owner != address(0)) revert AlreadyInitialized();
        if (_owner == address(0)) revert NewOwnerIsZero();

        owner = _owner;
        myVar = _initialVar;

        emit Initialized(_owner, _initialVar);
    }

    /* ----------------------------- Bisnis/fungsional -------------------------- */
    /// @notice Ubah myVar (contoh fungsi yang dulunya kamu sebut "setData").
    function setData(uint256 _data) external onlyOwner {
        uint256 old = myVar;
        myVar = _data;
        emit MyVarUpdated(old, _data);
    }

    /// @notice Pindah kepemilikan logic (bukan admin proxy).
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert NewOwnerIsZero();
        address old = owner;
        owner = newOwner;
        emit OwnershipTransferred(old, newOwner);
    }
}
