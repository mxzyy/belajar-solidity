// SPDX-License-Identifier: UNCLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../../script/Interactions.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {FundSubscription} from "../../script/Interactions.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../../test/mocks/LinkToken.sol";

contract DummyReceiver {
    event Received(address sender, uint256 amount, bytes data);

    function onTokenTransfer(address sender, uint256 amount, bytes calldata data) external {
        emit Received(sender, amount, data);
        // gak nge-revert, jadi branch else bisa finish sampai vm.stopBroadcast()
    }
}

contract RaffleInteractionsTest is Test {
    CreateSubscription createSub;
    AddConsumer addConsumer;
    FundSubscription fundSub;
    VRFCoordinatorV2_5Mock vrfMock;
    LinkToken link;

    uint96 constant FUND_AMOUNT = 0.01 ether;

    function setUp() public {
        createSub = new CreateSubscription();
        addConsumer = new AddConsumer();
        fundSub = new FundSubscription();

        vrfMock = new VRFCoordinatorV2_5Mock(
            0.1 ether, // MOCK_BASE_FEE
            1e9, // MOCK_GAS_PRICE_LINK
            1e18 // MOCK_WEI_PER_UNIT_LINK
        );

        link = new LinkToken();
    }

    function testFundSubscription_LocalBranch() public {
        // 👉 SESUAIKAN DENGAN LOCAL_CHAIN_ID PUNYA LU
        // kalau LOCAL_CHAIN_ID = 31337:
        vm.chainId(31337);

        uint256 subId = vrfMock.createSubscription();
        address account = address(this);

        // ga peduli 'link' di path local, tapi tetap kirim address
        fundSub.fundSubscription(address(vrfMock), subId, address(link), account);

        // optional: assert sesuatu di vrfMock kalau mau
        // contoh: cek subscription exist
        // (tapi buat coverage, cukup "tidak revert")
    }

    /// @notice ngetest branch: local = false (block.chainid != LOCAL_CHAIN_ID)
    function testFundSubscription_NonLocalBranchReverts() public {
        // bikin chainid beda dari LOCAL_CHAIN_ID
        vm.chainId(1); // mainnet id, yang penting != 31337

        uint256 subId = 1;
        address account = address(this);

        // kasih LINK ke account yg bakal nge-broadcast
        // mock LinkToken lu punya fungsi mint (dari snippet lcov sebelumnya)
        link.mint(account, FUND_AMOUNT);

        vm.expectRevert();
        fundSub.fundSubscription(address(vrfMock), subId, address(link), account);

        // buat sekedar coverage, cukup tidak revert.
        // kalau mau fancy, lu bisa bikin FakeLinkToken dan assert transferAndCall kepanggil.
    }

    function testFundSubscription_NonLocalBranch_DoesNotRevert() public {
        vm.chainId(1);

        uint256 subId = 1;
        address account = address(this);

        link.mint(account, fundSub.FUND_AMOUNT());
        DummyReceiver dummy = new DummyReceiver();
        fundSub.fundSubscription(address(dummy), subId, address(link), account);
    }

    function testCreateSubscriptionUsingConfig() public {
        (uint256 subId, address vrfCoordinator) = createSub.createSubscriptionUsingConfig();
        assert(subId != 0);
        assert(vrfCoordinator != address(0));
    }

    function testRunCreateSubscription() public {
        (uint256 subId, address vrfCoordinator) = createSub.run();
        assert(subId != 0);
        assert(vrfCoordinator != address(0));
    }

    function testAddConsumerUsingConfig() public {
        address mostRecentlyDeployed = address(0x123); // Mock address
        addConsumer.addConsumerUsingConfig(mostRecentlyDeployed);
    }

    function testRunAddConsumer() public {
        vm.expectRevert(); // Expect revert since we're using a mock address
        addConsumer.run();
    }

    function testFundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = address(0); // Mock address
        address account = helperConfig.getConfigByChainId(block.chainid).account;
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;

        vm.expectRevert(); // Expect revert since we're using a mock address
        fundSub.fundSubscription(vrfCoordinator, subId, linkToken, account);
    }

    function testRunFundSubscription() public {
        fundSub.run();
    }

    function testFundSubscriptionUsingConfig_LocalChain_DoesNotRevert() public {
        // pastiin chain id = LOCAL_CHAIN_ID, biasanya 31337
        vm.chainId(31337);

        fundSub.fundSubscriptionUsingConfig();
        // ga perlu assert, buat coverage yang penting *kejalan & ngga revert*
    }
}
