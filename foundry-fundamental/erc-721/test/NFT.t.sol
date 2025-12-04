// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DeployNFT} from "../script/Deploy.s.sol";
import {NFT} from "../src/NFT.sol";

contract NFTTest is Test {
    DeployNFT deployer;
    NFT nft;

    function setUp() public {
        deployer = new DeployNFT();
        nft = deployer.run();
    }

    function testMintNFT() public {
        address recipient = address(1);
        string memory tokenUri = "ipfs://token-1";
        vm.prank(recipient);
        uint256 tokenId = nft.mint(recipient, tokenUri);

        assertEq(tokenId, 1);
        assertEq(nft.ownerOf(tokenId), recipient);
        assertEq(nft.tokenURI(tokenId), tokenUri);
    }
}
