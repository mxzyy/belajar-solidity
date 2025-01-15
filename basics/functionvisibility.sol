// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract publicVisibility {
    function publicFunction() public pure returns (string memory) {
        return "This is a public function.";
    }
}

contract Test {
    publicVisibility public example;

    constructor(address _exampleAddress) {
        example = publicVisibility(_exampleAddress);
    }

    function callPublicFunction() public view returns (string memory) {
        return example.publicFunction(); // Ini valid jika `publicFunction` adalah `pure` atau `view`
    }
}
