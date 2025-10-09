// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {DevOpsTools} from "foundry-devops/DevOpsTools.sol";

interface IFundMeLike {
    function fund() external payable;
    function withdraw() external;
}

interface IDevOpsTools {
    function get_most_recent_deployment(string memory, uint256) external returns (address);
}

// default adapter ke DevOpsTools asli
contract DevOpsToolsLike is IDevOpsTools {
    function get_most_recent_deployment(string memory name, uint256 chainid) external view override returns (address) {
        return DevOpsTools.get_most_recent_deployment(name, chainid);
    }
}

contract FundMe_Fund_InteractionContract is Script {
    uint256 constant SEND_VALUE = 0.1 ether;

    IDevOpsTools public tools = new DevOpsToolsLike();

    // --- hooks: bisa dioverride di test agar broadcast jadi no-op
    function _before() internal virtual {
        vm.startBroadcast();
    }

    function _after() internal virtual {
        vm.stopBroadcast();
    }

    // --- core yang dapat dipanggil dari test
    function _fundCore(address recentCA, uint256 amount) internal {
        IFundMeLike(payable(recentCA)).fund{value: amount}();
    }

    function FundMe_Fund_Interaction(address recentCA) public {
        _before();
        _fundCore(recentCA, SEND_VALUE);
        console.log("Funded FundMe contract with %s", SEND_VALUE);
        _after();
    }

    function run() public {
        address recentCA = tools.get_most_recent_deployment("FundMe", block.chainid);
        FundMe_Fund_Interaction(recentCA);
    }
}

contract FundMe_Withdraw_InteractionContract is Script {
    IDevOpsTools public tools = new DevOpsToolsLike();

    function _before() internal virtual {
        vm.startBroadcast();
    }

    function _after() internal virtual {
        vm.stopBroadcast();
    }

    function _withdrawCore(address recentCA) internal {
        IFundMeLike(payable(recentCA)).withdraw();
    }

    function FundMe_Withdraw_Interaction(address recentCA) public {
        _before();
        _withdrawCore(recentCA);
        console.log("Withdrew from FundMe contract");
        _after();
    }

    function run() public {
        address recentCA = tools.get_most_recent_deployment("FundMe", block.chainid);
        FundMe_Withdraw_Interaction(recentCA);
    }
}
