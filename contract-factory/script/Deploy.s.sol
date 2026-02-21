// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {CF, Wallet} from "../src/CF.sol";

/// forge script script/deploy.s.sol:Deploy --rpc-url $RPC --private-key $PK --broadcast -vvvv
contract Deploy is Script {
    /// @notice Deploy CF (ContractFactory) saja.
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY"); // wajib
        vm.startBroadcast(pk);
        CF cf = new CF();
        vm.stopBroadcast();

        console2.log("CF deployed at:", address(cf));
    }

    /// @notice Prediksi alamat Wallet deterministik (tanpa deploy).
    /// forge script script/deploy.s.sol:Deploy --sig "predict(address,bytes32,address)" $CF $OWNER $SALT $RPC/PK optional via env
    function predict(address cfAddr, bytes32 salt, address owner) external view {
        CF cf = CF(payable(cfAddr));
        address predicted = cf.predictWalletAddress(owner, salt);
        console2.log("Predicted wallet:", predicted);
    }

    /// @notice Deploy Wallet deterministik via CF (CREATE2).
    /// Env yang dibaca:
    /// - PRIVATE_KEY   (uint)     : pk deployer
    /// - CF            (address)  : alamat factory (CF) yang sudah ada
    /// - WALLET_OWNER  (address)  : owner wallet
    /// - SALT          (bytes32)  : salt create2
    /// - PREFUND       (bool)     : jika true, kirim VALUE ke alamat counterfactual sebelum deploy
    /// - VALUE         (uint)     : nilai ETH yang dikirim (prefund ATAU saat deploy)
    ///
    /// Contoh:
    /// PRIVATE_KEY=0xabc CF=0xCF... WALLET_OWNER=0xOWN... SALT=0x123... PREFUND=true VALUE=100000000000000000 \
    /// forge script script/deploy.s.sol:Deploy --sig "deployWalletDeterministic()" --rpc-url $RPC --broadcast -vvvv
    function deployWalletDeterministic() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address cfAddr = vm.envAddress("CF");
        address owner = vm.envAddress("WALLET_OWNER");
        bytes32 salt = vm.envBytes32("SALT");
        bool prefund = vm.envBool("PREFUND");
        uint256 valueWei = vm.envUint("VALUE"); // boleh 0

        CF cf = CF(payable(cfAddr));

        // precompute address
        address predicted = cf.predictWalletAddress(owner, salt);
        console2.log("CF           :", cfAddr);
        console2.log("Owner        :", owner);
        console2.logBytes32(salt);
        console2.log("Predicted    :", predicted);
        console2.log("Prefund?     :", prefund);
        console2.log("VALUE (wei)  :", valueWei);

        vm.startBroadcast(pk);

        if (prefund && valueWei > 0) {
            // Kirim ETH ke alamat counterfactual SEBELUM deploy (counterfactual funding)
            (bool ok,) = payable(predicted).call{value: valueWei}("");
            require(ok, "prefund transfer failed");
            // Deploy tanpa value tambahan
            address deployed = cf.deployWalletDeterministic{value: 0}(owner, salt);
            require(deployed == predicted, "deployed != predicted");
            console2.log("Wallet (redeemed):", deployed);
        } else {
            // Tidak prefund: kirim ETH (jika ada) saat deploy
            address deployed = cf.deployWalletDeterministic{value: valueWei}(owner, salt);
            require(deployed == predicted, "deployed != predicted");
            console2.log("Wallet (fresh)   :", deployed);
        }

        vm.stopBroadcast();
    }

    /// @notice Deploy Wallet jalur CREATE (non-deterministic) + value saat deploy.
    /// Env:
    /// - PRIVATE_KEY, CF, WALLET_OWNER, VALUE
    /// Contoh:
    /// PRIVATE_KEY=0x... CF=0xCF... WALLET_OWNER=0x... VALUE=1e17 \
    /// forge script script/deploy.s.sol:Deploy --sig "deployCreate()" --rpc-url $RPC --broadcast -vvvv
    function deployCreate() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address cfAddr = vm.envAddress("CF");
        address owner = vm.envAddress("WALLET_OWNER");
        uint256 valueWei = vm.envUint("VALUE");

        CF cf = CF(payable(cfAddr));

        vm.startBroadcast(pk);
        address w = cf.deployWallet{value: valueWei}(owner);
        vm.stopBroadcast();

        console2.log("Wallet (CREATE):", w);
    }
}
