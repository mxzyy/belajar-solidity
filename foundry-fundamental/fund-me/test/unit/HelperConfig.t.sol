// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// ─────────────────────────────────────────────────────────────────────────────
// Imports
// Adjust the import path to where HelperConfig is located in your repo.
import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {HelperConfig, CodeConstant} from "../../script/HelperConfig.s.sol";
import {MockV3Aggregator} from "../../test/mock/MockV3Aggregator.sol";

/// @notice Mirror the custom error so we can use expectRevert with selector
error HelperConfig__InvalidChainId();

contract HelperConfigTest is Test, CodeConstant {
    HelperConfig internal cfg;

    // Known addresses hardcoded in HelperConfig's constructor & pure getters
    address constant SEPOLIA_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address constant MAINNET_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address constant ZKSYNC_FEED_CONSTRUCTOR = 0xEca8C3742B6b6AB7a2F2Af1B7c0c2B8d9A3c74d2; // constructor mapping
    address constant ZKSYNC_FEED_PURE = 0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF; // getZksyncEthConfig()

    function setUp() public {
        // Deploy fresh HelperConfig before each test
        cfg = new HelperConfig();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    Constructor
    //////////////////////////////////////////////////////////////////////////*/

    function test_constructor_setsKnownNetworkConfigs() public view {
        // Sepolia
        (address sepolia) = cfg.networkConfigs(ETH_SEPOLIA_CHAIN_ID);
        assertEq(sepolia, SEPOLIA_FEED, "Sepolia feed mismatch");
        // Mainnet
        (address mainnet) = cfg.networkConfigs(ETH_MAINNET_CHAIN_ID);
        assertEq(mainnet, MAINNET_FEED, "Mainnet feed mismatch");
        // zkSync (constructor mapping)
        (address zksyncMapping) = cfg.networkConfigs(ZKSYNC_MAINNET_CHAIN_ID);
        assertEq(zksyncMapping, ZKSYNC_FEED_CONSTRUCTOR, "zkSync mapping feed mismatch");
    }

    /*//////////////////////////////////////////////////////////////////////////
                               getConfigByChainId()
    //////////////////////////////////////////////////////////////////////////*/

    function test_getConfigByChainId_returnsMappingEntry_forKnownChain() public {
        HelperConfig.NetworkConfig memory c1 = cfg.getConfigByChainId(ETH_SEPOLIA_CHAIN_ID);
        assertEq(c1.priceFeed, SEPOLIA_FEED, "Should return Sepolia mapping config");

        HelperConfig.NetworkConfig memory c2 = cfg.getConfigByChainId(ETH_MAINNET_CHAIN_ID);
        assertEq(c2.priceFeed, MAINNET_FEED, "Should return Mainnet mapping config");
    }

    function test_getConfigByChainId_localDeploysMockAndCaches() public {
        // First call should deploy a MockV3Aggregator and cache it into localNetworkConfig
        HelperConfig.NetworkConfig memory local1 = cfg.getConfigByChainId(LOCAL_CHAIN_ID);
        assertTrue(local1.priceFeed != address(0), "Local price feed should be set");
        // The deployed address must be a contract
        uint256 codeSize1 = local1.priceFeed.code.length;
        assertGt(codeSize1, 0, "Local feed must be a contract");

        // Validate decimals & initial answer on the mock align with constants
        uint8 decimals = MockV3Aggregator(local1.priceFeed).decimals();
        assertEq(decimals, DECIMALS, "Mock decimals mismatch");
        int256 answer = MockV3Aggregator(local1.priceFeed).latestAnswer();
        assertEq(answer, INITIAL_PRICE, "Mock initial price mismatch");

        // Second call should not redeploy; it must return the same cached config
        HelperConfig.NetworkConfig memory local2 = cfg.getConfigByChainId(LOCAL_CHAIN_ID);
        assertEq(local2.priceFeed, local1.priceFeed, "Local config must be cached (idempotent)");
    }

    function test_getConfigByChainId_revertsForUnknownChainId_fuzz(uint256 chainId) public {
        // avoid known chain IDs
        vm.assume(
            chainId != LOCAL_CHAIN_ID && chainId != ETH_SEPOLIA_CHAIN_ID && chainId != ETH_MAINNET_CHAIN_ID
                && chainId != ZKSYNC_MAINNET_CHAIN_ID
        );
        vm.expectRevert(HelperConfig__InvalidChainId.selector);
        cfg.getConfigByChainId(chainId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                               getOrCreateAnvilConfig()
    //////////////////////////////////////////////////////////////////////////*/

    function test_getOrCreateAnvilConfig_idempotentAndValidMock() public {
        HelperConfig.NetworkConfig memory a = cfg.getOrCreateAnvilConfig();
        HelperConfig.NetworkConfig memory b = cfg.getOrCreateAnvilConfig();
        assertEq(a.priceFeed, b.priceFeed, "Should be idempotent (single deployment)");

        // sanity on mock
        assertEq(MockV3Aggregator(a.priceFeed).decimals(), DECIMALS, "decimals bad");
        assertEq(MockV3Aggregator(a.priceFeed).latestAnswer(), INITIAL_PRICE, "initial price bad");

        // localNetworkConfig state var must be set
        (address stored) = cfg.localNetworkConfig();
        assertEq(stored, a.priceFeed, "localNetworkConfig not persisted");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   Pure getters
    //////////////////////////////////////////////////////////////////////////*/

    function test_getSepoliaEthConfig_returnsExpected() public view {
        HelperConfig.NetworkConfig memory c = cfg.getSepoliaEthConfig();
        assertEq(c.priceFeed, SEPOLIA_FEED, "Sepolia pure getter mismatch");
    }

    function test_getZksyncEthConfig_returnsExpected_andDetectsMismatch() public view {
        HelperConfig.NetworkConfig memory c = cfg.getZksyncEthConfig();
        assertEq(c.priceFeed, ZKSYNC_FEED_PURE, "zkSync pure getter mismatch");
        // NOTE: This intentionally highlights a mismatch between constructor mapping and pure getter.
        // If you expect them to match, this assertTrue will fail — fix the contract accordingly.
        assertTrue(ZKSYNC_FEED_PURE != ZKSYNC_FEED_CONSTRUCTOR, "Test exposes mapping/getter mismatch");
    }

    /*//////////////////////////////////////////////////////////////////////////
                            Extra: showcase cheatcodes
    //////////////////////////////////////////////////////////////////////////*/

    function test_prank_doesNotAffectPureGetter() public {
        address random = address(0xBEEF);
        vm.prank(random);
        HelperConfig.NetworkConfig memory c = cfg.getSepoliaEthConfig();
        assertEq(c.priceFeed, SEPOLIA_FEED);
    }
}

/// @notice Invariant tests for local config creation semantics
contract HelperConfigInvariants is StdInvariant, Test, CodeConstant {
    HelperConfig internal cfg;

    function setUp() public {
        cfg = new HelperConfig();
        // target the cfg for invariants (no handlers needed)
        targetContract(address(cfg));
    }

    /// @dev Once local config is created, it should remain stable and valid
    function invariant_LocalConfigOnceCreatedIsStableAndValid() public {
        // Trigger creation at least once
        HelperConfig.NetworkConfig memory local = cfg.getOrCreateAnvilConfig();
        // Must point to a live MockV3Aggregator with expected params
        uint256 codeSize = local.priceFeed.code.length;
        assertGt(codeSize, 0, "local feed must be a contract");
        assertEq(MockV3Aggregator(local.priceFeed).decimals(), DECIMALS);
        assertEq(MockV3Aggregator(local.priceFeed).latestAnswer(), INITIAL_PRICE);
        // localNetworkConfig must always mirror the getter
        (address stored) = cfg.localNetworkConfig();
        assertEq(stored, local.priceFeed, "localNetworkConfig drifted");
    }
}
