// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";

/// @title DeploySimpleStorage Script
/// @author github.com/@mxzyy
/// @notice Foundry script to deploy `SimpleStorage` contract into the blockchain
/// @dev Not using any env's private key in the code. Use CLI flag/keystore during execution.
contract DeploySimpleStorage is Script {
    /// @notice Deploy the `SimpleStorage` contract.
    /// @dev `vm.startBroadcast()` will broadcast the transaction using the credentials you provide via CLI/keystore.
    /// @return simpleStorage Instance of the newly deployed contract.
    function run() external returns (SimpleStorage simpleStorage) {
        // ------------------------------------------------------------
        // 1) Start broadcasting the transaction
        //    Use the key via:
        //    - `--private-key ...`  or
        //    - `--account ...` (Foundry keystore)
        //    No ENV reading in the code.
        // ------------------------------------------------------------
        vm.startBroadcast();

        // ------------------------------------------------------------
        // 2) Deploy the contract
        // ------------------------------------------------------------
        simpleStorage = new SimpleStorage();

        // ------------------------------------------------------------
        // 3) Stop broadcasting the transaction
        // ------------------------------------------------------------
        vm.stopBroadcast();

        // ------------------------------------------------------------
        // 4) Logging important information to the terminal
        // ------------------------------------------------------------
        console2.log("SimpleStorage deployed!");
        console2.log("Address:", address(simpleStorage));
        console2.log("Deployer:", msg.sender);
        console2.log("Chain ID:", block.chainid);

        return simpleStorage;
    }
}
