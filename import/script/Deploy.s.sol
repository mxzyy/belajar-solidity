// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {ImportExample} from "../src/Import.sol";
import {IERC20} from "../src/Interfaces.sol";

/* ---------------------------------------------------------- */
/*                         MockERC20                           */
/* ---------------------------------------------------------- */
// Top-level (bukan nested) agar valid di Solidity & bisa dipakai Script di bawah.
contract MockERC20 {
    string public name = "Mock";
    string public symbol = "MOCK";
    uint8 public decimals = 18;

    uint256 private _totalSupply;
    mapping(address => uint256) private _bal;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function mint(address to, uint256 amount) external {
        _totalSupply += amount;
        _bal[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _bal[account];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        address from = msg.sender;
        uint256 bal = _bal[from];
        require(bal >= amount, "ERC20: balance too low");
        unchecked {
            _bal[from] = bal - amount;
            _bal[to] += amount;
        }
        emit Transfer(from, to, amount);
        return true;
    }
}

/* ---------------------------------------------------------- */
/*                         Deploy Script                       */
/* ---------------------------------------------------------- */
contract Deploy is Script {
    uint256 internal constant DEFAULT_MINT = 1_000 ether;

    /**
     * ENV:
     * - PRIVATE_KEY : (wajib) private key deployer (0x...)
     * - TOKEN_ADDR  : (opsional) alamat ERC20 existing; jika kosong, deploy MockERC20
     * - MINT_AMOUNT : (opsional) jumlah mint saat mock dipakai; default 1_000 ether
     *
     * Contoh:
     * forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast -vvvv
     */
    function run() external {
        // 1) Load ENV
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);
        address tokenAddr = _tryGetEnvAddress("TOKEN_ADDR");
        uint256 mintAmount = _tryGetEnvUint("MINT_AMOUNT", DEFAULT_MINT);

        // 2) Start broadcast
        vm.startBroadcast(pk);

        // 3) Tentukan token (existing vs mock)
        IERC20 token;
        bool usingMock = false;

        if (tokenAddr == address(0)) {
            // Deploy mock jika TOKEN_ADDR tidak di-set
            MockERC20 mock = new MockERC20();
            token = IERC20(address(mock));
            usingMock = true;

            // Seed saldo ke deployer (opsional)
            mock.mint(deployer, mintAmount);
        } else {
            token = IERC20(tokenAddr);
        }

        // 4) Deploy ImportExample
        ImportExample imp = new ImportExample(address(token));

        // 5) Jika mock, seed saldo ke kontrak agar siap reward
        if (usingMock) {
            MockERC20(address(token)).mint(address(imp), mintAmount);
        }

        vm.stopBroadcast();

        // 6) Logging ringkas
        _logDeployment(deployer, address(imp), address(token), usingMock, mintAmount);
    }

    // ------------------------ Helpers ------------------------

    function _logDeployment(address deployer, address imp, address token, bool usingMock, uint256 minted)
        internal
        view
    {
        uint256 cid;
        assembly {
            cid := chainid()
        }

        console2.log("== Deployment Summary ==");
        console2.log("Deployer          :", deployer);
        console2.log("Chain ID          :", cid);
        console2.log("ImportExample     :", imp);
        console2.log("Token (IERC20)    :", token);
        console2.log("Using Mock Token? :", usingMock);
        if (usingMock) {
            console2.log("Mock Mint Amount  :", minted);
        }

        // Cek saldo token kontrak (IERC20 kita punya balanceOf)
        try IERC20(token).balanceOf(imp) returns (uint256 bal) {
            console2.log("Contract token bal:", bal);
        } catch {
            console2.log("Contract token bal: (cannot fetch)");
        }
    }

    function _tryGetEnvAddress(string memory key) internal view returns (address) {
        string memory s = _getEnvStringOrEmpty(key);
        if (bytes(s).length == 0) return address(0);
        return vm.parseAddress(s);
    }

    function _tryGetEnvUint(string memory key, uint256 fallbackValue) internal view returns (uint256) {
        string memory s = _getEnvStringOrEmpty(key);
        if (bytes(s).length == 0) return fallbackValue;
        return vm.parseUint(s);
    }

    function _getEnvStringOrEmpty(string memory key) internal view returns (string memory) {
        // Prefer vm.envString; jika tidak ada env, kembalikan "".
        try this._envString(key) returns (string memory val) {
            return val;
        } catch {
            return "";
        }
    }

    // Wrapper agar bisa try/catch cheatcodes di atas
    function _envString(string memory key) external view returns (string memory) {
        return vm.envString(key);
    }
}
