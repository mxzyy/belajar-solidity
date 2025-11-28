// SPDX-License-Identifier: UNCLICENSED
pragma solidity ^0.8.20;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../mocks/LinkToken.sol";
import {codeConstants} from "../../script/HelperConfig.s.sol";
import {RaffleDeployerLib} from "../../src/RaffleDeployerLib.sol";

contract RaffleDeployerLibHarness {
    function callPrepareRawCallbackGasLimit(uint256 rawGasLimit) external pure returns (uint32) {
        return RaffleDeployerLib.prepareRawCallbackGasLimit(rawGasLimit);
    }
}

contract RaffleLibraryTest is Test, codeConstants {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed player);

    /*//////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    Raffle public raffle;
    HelperConfig public helperConfig;
    RaffleDeployerLibHarness public harness;

    uint256 subscriptionId;
    bytes32 gasLane;
    uint256 automationUpdateInterval;
    uint256 raffleEntranceFee;
    uint32 callbackGasLimit;
    address vrfCoordinatorV2_5;
    LinkToken link;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint96 public constant LINK_BALANCE = 100 ether;

    /*//////////////////////////////////////////////////////////////
                               SETUP
    //////////////////////////////////////////////////////////////*/
    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        vm.deal(PLAYER, STARTING_USER_BALANCE);

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        harness = new RaffleDeployerLibHarness();
        subscriptionId = config.subscriptionId;
        gasLane = config.gasLane;
        automationUpdateInterval = config.automationUpdateInterval;
        raffleEntranceFee = config.raffleEntranceFee;
        callbackGasLimit = config.callbackGasLimit;
        vrfCoordinatorV2_5 = config.vrfCoordinatorV2_5;
        link = LinkToken(config.link);

        vm.startPrank(msg.sender);

        if (block.chainid == LOCAL_CHAIN_ID) {
            VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fundSubscription(subscriptionId, LINK_BALANCE);
        }

        link.approve(vrfCoordinatorV2_5, LINK_BALANCE);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            LIBRARY TESTS
    //////////////////////////////////////////////////////////////*/

    function testRaffleDeployerLibPrepareConfig() public {
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        // Simulate a zero subscriptionId to trigger creation
        config.subscriptionId = 0;

        HelperConfig.NetworkConfig memory updatedConfig = RaffleDeployerLib.prepareConfig(config);

        assert(updatedConfig.subscriptionId != 0);
    }

    function testRaffleDeployerLibPrepareRawCallbackGasLimit() public pure {
        uint256 rawGasLimit = 250000;
        uint32 gasLimit = RaffleDeployerLib.prepareRawCallbackGasLimit(rawGasLimit);

        assertEq(gasLimit, uint32(rawGasLimit));
    }

    function testRaffleDeployerLibRawCallbackRevertOnTooLarge() public {
        uint256 rawGasLimit = uint256(type(uint32).max) + 1;

        // kalau di lib lu pakai require(..., "CALLBACK_GAS_LIMIT too large")
        vm.expectRevert(bytes("CALLBACK_GAS_LIMIT too large"));
        harness.callPrepareRawCallbackGasLimit(rawGasLimit);
    }

    function testRaffleDeployerLibRawCallbackOk() public view {
        uint256 rawGasLimit = uint256(type(uint32).max);

        uint32 gasLimit = harness.callPrepareRawCallbackGasLimit(rawGasLimit);
        assertEq(gasLimit, uint32(rawGasLimit));
    }
}
