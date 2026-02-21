// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// -----------------------------------------------------------------
// -                                                               -
// - INTERFACE (HANYA DEKLARASI FUNCTION, EVENT, DAN CUSTOM ERROR) -
// -                                                               -
// -----------------------------------------------------------------
interface ICounter {
    event Incremented(address indexed by, uint256 newValue);

    error NotAllowed();

    function increment() external;
    function value() external view returns (uint256);
}

contract Counter is ICounter {
    uint256 private _v;

    function increment() external override {
        _v += 1;
        emit Incremented(msg.sender, _v);
    }

    // Boleh public (lebih longgar dari external)
    function value() public view override returns (uint256) {
        return _v;
    }
}
