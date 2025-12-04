//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {NFT} from "../src/NFT.sol";

contract DeployNFT is Script {
    function run() external returns (NFT nft) {
        vm.startBroadcast();
        nft = new NFT();
        vm.stopBroadcast();
    }
}
