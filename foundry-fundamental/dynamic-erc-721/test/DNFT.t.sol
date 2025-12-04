// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DynamicNFTScript} from "../script/Deploy.s.sol";
import {DynamicNFT} from "../src/DNFT.sol";

contract DynamicNFTScriptTest is Test {
    DynamicNFTScript public dynamicNFTScript;

    function setUp() public {
        dynamicNFTScript = new DynamicNFTScript();
        dynamicNFTScript.setUp();
    }

    function testDeploy() public view {
        DynamicNFT dynamicNFT = dynamicNFTScript.dynamicNFT();
        address dynamicNFTAddress = address(dynamicNFT);

        console.logAddress(dynamicNFTAddress);
        assert(dynamicNFTAddress != address(0));
    }

    function testMintAndSetTokenURI() public {
        DynamicNFT dynamicNFT = dynamicNFTScript.dynamicNFT();
        uint256 tokenId = 1;
        string memory tokenURI = "https://example.com/token/1";

        // Mint the NFT
        dynamicNFT.mint(address(this), tokenId);

        // Set the token URI
        dynamicNFT.setTokenURI(tokenId, tokenURI);

        // Verify the token URI
        string memory fetchedTokenURI = dynamicNFT.tokenURI(tokenId);
        assert(keccak256(abi.encodePacked(fetchedTokenURI)) == keccak256(abi.encodePacked(tokenURI)));
    }

    function testChangeTokenURI() public {
        DynamicNFT dynamicNFT = dynamicNFTScript.dynamicNFT();
        uint256 tokenId = 2;
        string memory initialTokenURI = "https://example.com/token/2";
        string memory updatedTokenURI = "https://example.com/token/2-updated";

        // Mint the NFT
        dynamicNFT.mint(address(this), tokenId);

        // Set the initial token URI
        dynamicNFT.setTokenURI(tokenId, initialTokenURI);

        // Update the token URI
        dynamicNFT.setTokenURI(tokenId, updatedTokenURI);

        // Verify the updated token URI
        string memory fetchedTokenURI = dynamicNFT.tokenURI(tokenId);
        assert(keccak256(abi.encodePacked(fetchedTokenURI)) == keccak256(abi.encodePacked(updatedTokenURI)));
    }
}
