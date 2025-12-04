// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFT is ERC721URIStorage {
    uint256 private _tokenIds;

    constructor() ERC721("MyNFT", "MNFT") {}

    function mint(address to, string memory tokenUri) external returns (uint256) {
        _tokenIds++;
        uint256 tokenId = _tokenIds;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenUri);
        return tokenId;
    }
}
