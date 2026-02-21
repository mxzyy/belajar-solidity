// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {Example} from "../src/Library.sol";
import {IERC20} from "../src/Interfaces.sol";

/// Usage (lihat perintah run di bawah):
/// - Env yang dipakai:
///     * PRIVATE_KEY : private key deployer
///     * TOKEN       : alamat ERC20 yang dipakai Example
///     * PUBLIC_MATH : (opsional) alamat PublicMath untuk logging saja
/// - Library PublicMath HARUS dilink via --libraries
contract Deploy is Script {
    function run() external {
        address token = vm.envAddress("TOKEN");
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address pm = vm.envOr("PUBLIC_MATH", address(0));

        vm.startBroadcast(pk);

        // Deploy Example
        Example ex = new Example(IERC20(token));

        vm.stopBroadcast();

        console2.log("Deployer         :", vm.addr(pk));
        if (pm != address(0)) console2.log("PublicMath (hint):", pm);
        console2.log("TOKEN            :", token);
        console2.log("Example deployed :", address(ex));
    }
}
