// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ContractFactory (CF)
/// @notice Factory minimalis, production-minded, untuk deploy instance Wallet
///         mendukung CREATE2 (alamat deterministik) & funding saat deploy.
contract CF {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error ZeroOwner();
    error AlreadyDeployed(address at);
    error DeployFailed(bytes reason);
    error NotOwner();
    error InsufficientGas(uint256 have, uint256 need);

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event WalletDeployed(address indexed owner, address indexed wallet, bytes32 indexed salt, uint256 value);

    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/
    address public immutable owner; // admin opsional (untuk rescue)
    uint256 private _locked = 1; // reentrancy guard (1 = unlocked, 2 = locked)

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier nonReentrant() {
        if (_locked != 1) revert();
        _locked = 2;
        _;
        _locked = 1;
    }

    constructor() {
        owner = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPLOY (CREATE - non-deterministic)
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploy wallet biasa (CREATE), alamat tidak deterministik.
    function deployWallet(address _owner) external payable nonReentrant returns (address deployed) {
        if (_owner == address(0)) revert ZeroOwner();
        try new Wallet{value: msg.value}(_owner) returns (Wallet w) {
            deployed = address(w);
            emit WalletDeployed(_owner, deployed, bytes32(0), msg.value);
        } catch (bytes memory reason) {
            revert DeployFailed(reason);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        DEPLOY (CREATE2 - deterministik)
    //////////////////////////////////////////////////////////////*/

    /// @notice Prediksi alamat wallet deterministik (counterfactual) sebelum deploy.
    function predictWalletAddress(address _owner, bytes32 salt) public view returns (address predicted) {
        bytes memory initCode = abi.encodePacked(type(Wallet).creationCode, abi.encode(_owner));
        bytes32 initCodeHash = keccak256(initCode);
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xFF), address(this), salt, initCodeHash));
        predicted = address(uint160(uint256(hash)));
    }

    /// @notice Deploy wallet deterministik (CREATE2) + funding via msg.value.
    function deployWalletDeterministic(address _owner, bytes32 salt)
        external
        payable
        nonReentrant
        returns (address deployed)
    {
        if (_owner == address(0)) revert ZeroOwner();

        address predicted = predictWalletAddress(_owner, salt);
        if (_codeSize(predicted) != 0) revert AlreadyDeployed(predicted);

        try new Wallet{salt: salt, value: msg.value}(_owner) returns (Wallet w) {
            deployed = address(w);
            if (deployed != predicted) revert AlreadyDeployed(predicted);
            emit WalletDeployed(_owner, deployed, salt, msg.value);
        } catch (bytes memory reason) {
            revert DeployFailed(reason);
        }
    }

    /// @notice Varian "strict": tidak mengatur gas untuk constructor (tidak didukung),
    ///         tapi memastikan sisa gas memadai sebelum mencoba deploy.
    function deployWalletDeterministicStrict(address _owner, bytes32 salt, uint256 minGasLeft)
        external
        payable
        nonReentrant
        returns (address deployed)
    {
        if (_owner == address(0)) revert ZeroOwner();
        if (gasleft() < minGasLeft) revert InsufficientGas(gasleft(), minGasLeft);

        address predicted = predictWalletAddress(_owner, salt);
        if (_codeSize(predicted) != 0) revert AlreadyDeployed(predicted);

        try new Wallet{salt: salt, value: msg.value}(_owner) returns (Wallet w) {
            deployed = address(w);
            if (deployed != predicted) revert AlreadyDeployed(predicted);
            emit WalletDeployed(_owner, deployed, salt, msg.value);
        } catch (bytes memory reason) {
            revert DeployFailed(reason);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN / RESCUE
    //////////////////////////////////////////////////////////////*/

    function rescueETH(address payable to) external onlyOwner {
        to.transfer(address(this).balance);
    }

    receive() external payable {
        revert();
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/
    function _codeSize(address a) internal view returns (uint256 size) {
        assembly {
            size := extcodesize(a)
        }
    }
}

contract Wallet {
    address public immutable owner;

    error NotOwner();

    constructor(address _owner) payable {
        if (_owner == address(0)) revert();
        owner = _owner;
    }

    function withdrawAll(address payable to) external {
        if (msg.sender != owner) revert NotOwner();
        to.transfer(address(this).balance);
    }
}
