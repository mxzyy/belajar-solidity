// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*──────────────────────────────────────────────────────────────────────────────
|                               Errors (global)                                |
──────────────────────────────────────────────────────────────────────────────*/
error Unauthorized();
error ZeroAddress();
error EtherMismatch();
error DeployParamInvalid();

/*──────────────────────────────────────────────────────────────────────────────
|                                Interfaces                                    |
──────────────────────────────────────────────────────────────────────────────*/
/// @notice Contoh target untuk external call
interface ITarget {
    function risky(uint256 x) external payable returns (uint256);
}

/*──────────────────────────────────────────────────────────────────────────────
|                                Utils (Ownable)                               |
──────────────────────────────────────────────────────────────────────────────*/
/// @dev Ownable minimal, cukup untuk demo production patterns.
abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/*──────────────────────────────────────────────────────────────────────────────
|                         Example Child to be Deployed                          |
──────────────────────────────────────────────────────────────────────────────*/
/// @notice Child kontrak yang bisa gagal di constructor (untuk demontrasi try/new)
contract Child {
    address public immutable owner;
    uint256 public immutable seed;

    error ZeroOwner();
    error BadSeed();

    constructor(address _owner, uint256 _seed) payable {
        if (_owner == address(0)) revert ZeroOwner();
        if (_seed == 0) revert BadSeed();
        owner = _owner;
        seed = _seed;
        // … in real life: inisialisasi state lain, sanity checks, dsb.
    }
}

/*──────────────────────────────────────────────────────────────────────────────
|                                Main Contract                                 |
──────────────────────────────────────────────────────────────────────────────*/
contract TC is Ownable {
    /*---------------------------- Roles (Operator) ----------------------------*/
    mapping(address => bool) public operator;

    event OperatorUpdated(address indexed who, bool enabled);

    function setOperator(address who, bool enabled) external onlyOwner {
        if (who == address(0)) revert ZeroAddress();
        operator[who] = enabled;
        emit OperatorUpdated(who, enabled);
    }

    modifier onlyOperator() {
        if (!operator[msg.sender] && msg.sender != owner) revert Unauthorized();
        _;
    }

    /*------------------------------- Events ----------------------------------*/
    enum ReasonKind {
        None,
        Error,
        Panic,
        LowLevel
    }

    event ExternalCallSucceeded(address indexed target, bytes4 indexed selector, bytes result);

    event ExternalCallFailed( // terisi jika Error(string)
        // terisi jika Panic(uint)
        // terisi jika unknown
        address indexed target,
        bytes4 indexed selector,
        ReasonKind kind,
        string reasonStr,
        uint256 panicCode,
        bytes lowLevelData
    );

    event ChildDeployed(address indexed child, uint256 valueSent);
    event ChildDeployFailed(ReasonKind kind, string reasonStr, uint256 panicCode, bytes lowLevelData);

    /*------------------------ Try/Catch: External Call ------------------------*/
    /**
     * @notice Memanggil fungsi eksternal secara aman menggunakan try/catch.
     * @dev
     * - Hanya menerima call lewat interface yang known ABI (lebih aman daripada .call).
     * - Jika target revert, transaksi TIDAK ikut revert — error ditangkap dan di-emit.
     * - Gunakan untuk batch executor / aggregator agar satu kegagalan tidak membatalkan semuanya.
     */
    function safeExternalCall(
        address target,
        uint256 x, // contoh argumen untuk ITarget.risky(uint256)
        bytes4 selector, // untuk logging observability
        uint256 value
    ) external payable onlyOperator returns (bool ok, bytes memory resultOrEmpty) {
        if (msg.value != value) revert EtherMismatch();
        if (target == address(0)) revert ZeroAddress();

        // CHECKS done, no state to mutate → langsung INTERACTION (CEI)
        try ITarget(target).risky{value: value}(x) returns (uint256 out) {
            // Bungkus output agar generik (bytes) buat logging/ chaining
            bytes memory packed = abi.encode(out);
            emit ExternalCallSucceeded(target, selector, packed);
            return (true, packed);
        } catch Error(string memory reason) {
            emit ExternalCallFailed(target, selector, ReasonKind.Error, reason, 0, "");
            return (false, "");
        } catch Panic(uint256 code) {
            emit ExternalCallFailed(target, selector, ReasonKind.Panic, "", code, "");
            return (false, "");
        } catch (bytes memory lowLevel) {
            emit ExternalCallFailed(target, selector, ReasonKind.LowLevel, "", 0, lowLevel);
            return (false, "");
        }
    }

    /*--------------------------- Try/Catch: new -------------------------------*/
    /**
     * @notice Deploy kontrak Child dengan proteksi try/catch.
     * @dev
     * - Jika constructor Child revert, transaksi TIDAK ikut revert — error ditangkap dan di-emit.
     * - Cocok saat perlu melakukan banyak deployment, dan ingin skip yang gagal.
     */
    function safeDeployChild(address childOwner, uint256 seed)
        external
        payable
        onlyOperator
        returns (bool ok, address child)
    {
        // CEI: tidak mengubah state internal sebelum interaksi
        try new Child{value: msg.value}(childOwner, seed) returns (Child c) {
            emit ChildDeployed(address(c), msg.value);
            return (true, address(c));
        } catch Error(string memory reason) {
            emit ChildDeployFailed(ReasonKind.Error, reason, 0, "");
            return (false, address(0));
        } catch Panic(uint256 code) {
            emit ChildDeployFailed(ReasonKind.Panic, "", code, "");
            return (false, address(0));
        } catch (bytes memory lowLevel) {
            emit ChildDeployFailed(ReasonKind.LowLevel, "", 0, lowLevel);
            return (false, address(0));
        }
    }

    /*------------------------- Bonus: self external call ----------------------*/
    /**
     * @notice Contoh memaksa external call ke kontrak sendiri (agar bisa di-try/catch).
     * @dev
     * - `this.riskySelf(x)` = external call → bisa ditangkap try/catch.
     * - `riskySelf(x)` (tanpa `this`) = internal call → TIDAK bisa ditangkap.
     */
    function riskySelf(uint256 x) public pure returns (uint256) {
        require(x != 0, "x must be > 0");
        return 100 / x;
    }

    function safeExternalSelf(uint256 x) external view returns (bool ok, uint256 outOrZero) {
        try this.riskySelf(x) returns (uint256 out) {
            return (true, out);
        } catch Error(string memory) /*reason*/ {
            return (false, 0);
        } catch Panic(uint256) /*code*/ {
            return (false, 0);
        } catch (bytes memory) /*low*/ {
            return (false, 0);
        }
    }
}
