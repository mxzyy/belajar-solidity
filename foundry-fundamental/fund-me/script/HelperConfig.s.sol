// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {MockV3Aggregator} from "../test/mock/MockV3Aggregator.sol";
import {Script, console2} from "forge-std/Script.sol";

abstract contract CodeConstant {
    /* ============================ CONSTANT VARIBLE ============================ */
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8; // 2000 USDC

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant ZKSYNC_MAINNET_CHAIN_ID = 324;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstant, Script {
    /* ============================ CUSTOM ERRORS =============================== */
    error HelperConfig__InvalidChainId();

    /* ============================ TYPES ======================================= */
    struct NetworkConfig {
        address priceFeed; // ETH/USD price feed address
    }

    /* ============================ STATE VARIABLES ============================= */
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig config) public networkConfigs;

    /* ============================ UTIL ======================================== */
    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306 // Sepolia ETH/USD
        });
        networkConfigs[ETH_MAINNET_CHAIN_ID] = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 // Mainnet ETH/USD
        });
        networkConfigs[ZKSYNC_MAINNET_CHAIN_ID] = NetworkConfig({
            priceFeed: 0xEca8C3742B6b6AB7a2F2Af1B7c0c2B8d9A3c74d2 // ZkSync Mainnet ETH/USD
        });
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilConfig();
        }
        if (networkConfigs[chainId].priceFeed != address(0)) {
            return networkConfigs[chainId];
        }
        revert HelperConfig__InvalidChainId();
    }

    /* ============================= CONFIG ===================================== */
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306 // ETH / USD
        });
    }

    function getZksyncEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            priceFeed: 0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF // ETH / USD
        });
    }

    /* =========================== LOCAL  CONFIG ================================ */

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.priceFeed != address(0)) {
            return localNetworkConfig;
        }

        console2.log(unicode"⚠️ Local network config not found, deploying mocks...");
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});
        return localNetworkConfig;
    }
}
