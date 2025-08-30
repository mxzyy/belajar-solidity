// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal ERC20 interface untuk rescue token (bukan library).
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract SelectorGateway {
    /*//////////////////////////////////////////////////////////////
                              ROLES & STATE
    //////////////////////////////////////////////////////////////*/

    // Roles
    mapping(address => bool) private _admins;
    mapping(address => bool) private _operators;

    // Pausable
    bool private _paused;

    // Reentrancy guard
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    // Allowlist pair (target, selector)
    mapping(address => mapping(bytes4 => bool)) public allowed; // allowed[target][selector] => true/false

    /*//////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////*/
    error NotAdmin();
    error NotOperator();
    error Paused();
    error InvalidCalldata();
    error PairNotAllowed(address target, bytes4 selector);
    error EtherMismatch();

    /*//////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    event AdminSet(address indexed account, bool enabled);
    event OperatorSet(address indexed account, bool enabled);
    event PausedSet(bool paused);
    event AllowedPairSet(address indexed target, bytes4 indexed selector, bool allowed);
    event Executed(
        address indexed caller, address indexed target, bytes4 indexed selector, uint256 value, bytes result
    );
    event RescueETH(address indexed to, uint256 amount);
    event RescueToken(address indexed token, address indexed to, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyAdmin() {
        if (!_admins[msg.sender]) revert NotAdmin();
        _;
    }

    modifier onlyOperator() {
        if (!_operators[msg.sender]) revert NotOperator();
        _;
    }

    modifier notPaused() {
        if (_paused) revert Paused();
        _;
    }

    modifier nonReentrant() {
        if (_status == _ENTERED) revert();
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address initialAdmin) {
        require(initialAdmin != address(0), "zero admin");
        _admins[initialAdmin] = true;
        emit AdminSet(initialAdmin, true);
        _status = _NOT_ENTERED;
    }

    /*//////////////////////////////////////////////////////////////
                             ADMIN / OPERATOR
    //////////////////////////////////////////////////////////////*/
    function setAdmin(address account, bool enabled) external onlyAdmin {
        _admins[account] = enabled;
        emit AdminSet(account, enabled);
    }

    function setOperator(address account, bool enabled) external onlyAdmin {
        _operators[account] = enabled;
        emit OperatorSet(account, enabled);
    }

    function pause(bool value) external onlyAdmin {
        _paused = value;
        emit PausedSet(value);
    }

    /*//////////////////////////////////////////////////////////////
                               ALLOWLIST API
    //////////////////////////////////////////////////////////////*/
    function setAllowedPair(address target, bytes4 selector, bool _isAllowed) external onlyAdmin {
        require(target != address(0), "zero target");
        allowed[target][selector] = _isAllowed;
        emit AllowedPairSet(target, selector, _isAllowed);
    }

    function setAllowedPairsBatch(address[] calldata targets, bytes4[] calldata selectors, bool[] calldata flags)
        external
        onlyAdmin
    {
        uint256 n = targets.length;
        require(selectors.length == n && flags.length == n, "length mismatch");
        for (uint256 i; i < n; ++i) {
            require(targets[i] != address(0), "zero target");
            allowed[targets[i]][selectors[i]] = flags[i];
            emit AllowedPairSet(targets[i], selectors[i], flags[i]);
        }
    }

    function isAllowed(address target, bytes4 selector) external view returns (bool) {
        return allowed[target][selector];
    }

    /*//////////////////////////////////////////////////////////////
                                 EXECUTION
    //////////////////////////////////////////////////////////////*/
    /// @notice Eksekusi panggilan low-level ke `target` dengan `data` (calldata sudah berisi selector + args).
    ///         Hanya diizinkan jika (target, selector) ada di allowlist. Gas forwarding apa adanya.
    /// @param target Alamat kontrak tujuan.
    /// @param data   Calldata lengkap: [4-byte selector | encoded args].
    /// @param value  Ether yang ikut dikirim. Harus sama dengan msg.value.
    function exec(address target, bytes calldata data, uint256 value)
        external
        payable
        onlyOperator
        notPaused
        nonReentrant
        returns (bytes memory result)
    {
        if (msg.value != value) revert EtherMismatch();
        if (data.length < 4) revert InvalidCalldata();
        bytes4 selector = bytes4(
            (uint32(uint8(data[0])) << 24) | (uint32(uint8(data[1])) << 16) | (uint32(uint8(data[2])) << 8)
                | uint32(uint8(data[3]))
        );

        if (!allowed[target][selector]) revert PairNotAllowed(target, selector);

        (bool ok, bytes memory ret) = target.call{value: value}(data);
        if (!ok) {
            assembly {
                revert(add(ret, 0x20), mload(ret))
            }
        }

        emit Executed(msg.sender, target, selector, value, ret);
        return ret;
    }

    /*//////////////////////////////////////////////////////////////
                                  UTILITIES
    //////////////////////////////////////////////////////////////*/
    /// @notice Helper untuk mendapatkan selector dari signature string.
    ///         Contoh: selectorOf("transfer(address,uint256)")
    function selectorOf(string memory sig) external pure returns (bytes4) {
        return bytes4(keccak256(bytes(sig)));
    }

    /// @notice Helper contoh: kembalikan selector dari interface eksternal.
    ///         Misal untuk whitelist cepat: setAllowedPair(token, exampleTransferSelector(), true)
    function exampleTransferSelector() external pure returns (bytes4) {
        // Contoh menggunakan literal signature:
        return bytes4(keccak256("transfer(address,uint256)"));
        // Atau jika Anda punya interface eksternal: return IERC20.transfer.selector;
    }

    /*//////////////////////////////////////////////////////////////
                                  RESCUE
    //////////////////////////////////////////////////////////////*/
    function rescueETH(address to, uint256 amount) external onlyAdmin {
        require(to != address(0), "zero to");
        (bool ok,) = to.call{value: amount}("");
        require(ok, "eth send fail");
        emit RescueETH(to, amount);
    }

    function rescueToken(address token, address to, uint256 amount) external onlyAdmin {
        require(to != address(0), "zero to");
        bool ok = IERC20(token).transfer(to, amount);
        require(ok, "erc20 transfer fail");
        emit RescueToken(token, to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                              RECEIVE / FALLBACK
    //////////////////////////////////////////////////////////////*/
    receive() external payable {}
    fallback() external payable {}
}
