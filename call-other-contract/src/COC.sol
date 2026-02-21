// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* -------------------------------------------------------------------------- */
/*                               COMMON INTERFACES                             */
/* -------------------------------------------------------------------------- */

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

/* -------------------------------------------------------------------------- */
/*                               UTILITY LIBRARY                               */
/* -------------------------------------------------------------------------- */

library SafeAddress {
    error AddressEmpty();
    error CallFailed(bytes returndata);
    error StaticCallFailed(bytes returndata);
    error DelegateCallFailed(bytes returndata);

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        if (target == address(0)) revert AddressEmpty();
        (bool ok, bytes memory ret) = target.call(data);
        if (!ok) revert CallFailed(ret);
        return ret;
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (target == address(0)) revert AddressEmpty();
        (bool ok, bytes memory ret) = target.call{value: value}(data);
        if (!ok) revert CallFailed(ret);
        return ret;
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool ok, bytes memory ret) = target.staticcall(data);
        if (!ok) revert StaticCallFailed(ret);
        return ret;
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool ok, bytes memory ret) = target.delegatecall(data);
        if (!ok) revert DelegateCallFailed(ret);
        return ret;
    }
}

/* -------------------------------------------------------------------------- */
/*                        1) HIGH-LEVEL INTERFACE CALLS                        */
/* -------------------------------------------------------------------------- */

contract TokenSpender {
    using SafeAddress for address;

    error InsufficientAllowance();
    error TransferFailed();

    event Spent(address indexed token, address indexed from, address indexed to, uint256 amount);

    // Production notes:
    // - Strongly-typed interface calls with explicit checks.
    // - Accept both ERC-20s that return bool and those that revert on failure.
    function spend(address token, address from, address to, uint256 amount) external {
        // Pre-checks help fail-fast and improve analyzability
        uint256 allowed = IERC20(token).allowance(from, address(this));
        if (allowed < amount) revert InsufficientAllowance();

        // High-level call; handles tokens that return "true" or revert
        bool ok = IERC20(token).transferFrom(from, to, amount);
        // Some ERC-20s (USDT-like) return no value; in ^0.8.x, missing return decodes to false.
        if (!ok) revert TransferFailed();

        emit Spent(token, from, to, amount);
    }
}

/* -------------------------------------------------------------------------- */
/*                          2) LOW-LEVEL CALL (GENERIC)                        */
/* -------------------------------------------------------------------------- */

contract GenericCaller {
    using SafeAddress for address;

    event Called(address indexed target, bytes4 selector, bytes data, bytes result);

    // Example: call transfer(address,uint256) using a selector & raw encoding
    function callAny(address target, bytes4 selector, bytes calldata args) external returns (bytes memory) {
        // data layout: selector || args (already ABI-encoded args tuple)
        bytes memory payload = abi.encodePacked(selector, args);
        bytes memory ret = target.functionCall(payload); // reverts with reason if failed
        emit Called(target, selector, args, ret);
        return ret;
    }

    // Helper to encode arguments off-chain/other functions:
    function encode2(address a, uint256 b) external pure returns (bytes memory) {
        return abi.encode(a, b);
    }
}

/* -------------------------------------------------------------------------- */
/*                           3) DELEGATECALL (PROXY)                           */
/*        Minimal EIP-1967-like proxy with admin + upgrade + safety checks      */
/* -------------------------------------------------------------------------- */

contract UpgradeableProxy {
    using SafeAddress for address;

    // keccak256("eip1967.proxy.implementation") - 1
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    // keccak256("eip1967.proxy.admin") - 1
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    error NotAdmin();

    event Upgraded(address indexed newImplementation);

    constructor(address admin_, address implementation_, bytes memory initData) {
        assembly {
            sstore(_ADMIN_SLOT, admin_)
            sstore(_IMPLEMENTATION_SLOT, implementation_)
        }
        if (initData.length > 0) {
            implementation_.functionDelegateCall(initData);
        }
    }

    modifier onlyAdmin() {
        if (msg.sender != _admin()) revert NotAdmin();
        _;
    }

    function _admin() internal view returns (address a) {
        assembly {
            a := sload(_ADMIN_SLOT)
        }
    }

    function _implementation() internal view returns (address impl) {
        assembly {
            impl := sload(_IMPLEMENTATION_SLOT)
        }
    }

    function admin() external view returns (address) {
        return _admin();
    }

    function implementation() external view returns (address) {
        return _implementation();
    }

    function upgradeTo(address newImplementation, bytes calldata initData) external onlyAdmin {
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
        emit Upgraded(newImplementation);
        if (initData.length > 0) {
            newImplementation.functionDelegateCall(initData);
        }
    }

    fallback() external payable {
        address impl = _implementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}

/* -------------------------------------------------------------------------- */
/*                              4) STATICCALL (VIEW)                           */
/* -------------------------------------------------------------------------- */

interface IPriceOracle {
    function latestPrice() external view returns (uint256);
}

contract OracleReader {
    using SafeAddress for address;

    error BadReturnData();

    function readPrice(address oracle) external view returns (uint256 price) {
        bytes memory ret =
            SafeAddress.functionStaticCall(oracle, abi.encodeWithSelector(IPriceOracle.latestPrice.selector));
        if (ret.length != 32) revert BadReturnData();
        price = abi.decode(ret, (uint256));
    }
}

/* -------------------------------------------------------------------------- */
/*                5) SEND (NOT RECOMMENDED) — WRAPPED WITH PULLBACK           */
/* -------------------------------------------------------------------------- */

contract SendWrapper {
    mapping(address => uint256) public failedCredit; // fallback credit if send fails

    event Sent(address indexed to, uint256 amount, bool success);

    // Try to send with 2300 gas stipend; if it fails, credit balance for manual pull.
    function sendOrCredit(address payable to, uint256 amount) external payable {
        require(msg.value == amount, "must fund");
        bool ok = to.send(amount); // 2300 gas; may fail after EIP-1884
        if (!ok) {
            failedCredit[to] += amount; // record for pull-based withdrawal
        }
        emit Sent(to, amount, ok);
    }

    function withdrawCredit() external {
        uint256 amt = failedCredit[msg.sender];
        require(amt > 0, "no credit");
        failedCredit[msg.sender] = 0; // CEI
        (bool ok,) = payable(msg.sender).call{value: amt}("");
        require(ok, "call failed");
    }
}

/* -------------------------------------------------------------------------- */
/*                6) TRANSFER (NOT RECOMMENDED) — DEMO WITH REVERT            */
/* -------------------------------------------------------------------------- */

contract TransferWrapper {
    function pay(address payable to) external payable {
        // Will revert if recipient needs more than 2300 gas in receive/fallback
        to.transfer(msg.value);
    }
}

/* -------------------------------------------------------------------------- */
/*              7) CALL WITH VALUE (RECOMMENDED WAY TO SEND ETHER)            */
/* -------------------------------------------------------------------------- */

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status = _NOT_ENTERED;

    modifier nonReentrant() {
        require(_status != _ENTERED, "reentrant");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract PaymentProcessor is ReentrancyGuard {
    event Paid(address indexed to, uint256 amount);

    // Pull-pattern: users withdraw themselves; CEI + nonReentrant guard.
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(balances[msg.sender] >= amount, "insufficient");
        balances[msg.sender] -= amount; // Effects first (CEI)
        (bool ok,) = payable(msg.sender).call{value: amount}("");
        require(ok, "ETH send failed");
        emit Paid(msg.sender, amount);
    }

    // Direct pay using call with value (push) — only for trusted recipients
    function pay(address payable to, uint256 amount) external nonReentrant {
        (bool ok,) = to.call{value: amount}("");
        require(ok, "ETH send failed");
        emit Paid(to, amount);
    }
}

/* -------------------------------------------------------------------------- */
/*                       8) CONTRACT CREATION VIA `new`                       */
/* -------------------------------------------------------------------------- */

contract ChildContract {
    address public owner;
    uint256 public x;

    constructor(address _owner, uint256 _x) {
        owner = _owner;
        x = _x;
    }
}

contract ChildFactory {
    event Deployed(address indexed child, address indexed owner, uint256 x);

    function deploy(uint256 x) external returns (address child) {
        ChildContract c = new ChildContract(msg.sender, x);
        child = address(c);
        emit Deployed(child, msg.sender, x);
    }
}

/* -------------------------------------------------------------------------- */
/*                      EXAMPLE: USING LOW-LEVEL CALL SAFELY                   */
/* -------------------------------------------------------------------------- */

contract SafeERC20Caller {
    using SafeAddress for address;

    error ERC20CallFailed();

    // Works with non-standard ERC20s that (a) return bool, (b) return nothing but revert on failure
    function safeTransfer(address token, address to, uint256 amount) external {
        bytes memory ret = token.functionCall(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));
        // If token returns data, ensure it is true
        if (ret.length > 0) {
            bool ok = abi.decode(ret, (bool));
            if (!ok) revert ERC20CallFailed();
        }
    }
}
