// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract DynamicNFT is ERC721URIStorage {
    uint256 private _tokenIds;

    constructor() ERC721("DynamicNFT", "DNFT") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory uri) external {
        _setTokenURI(tokenId, uri);
    }
}
