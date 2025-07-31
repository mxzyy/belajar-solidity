// test/TokenRegistry.t.sol
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/TokenRegistry.sol";

contract TokenRegistryTest is Test {
    TokenRegistry reg;

    function setUp() public {
        reg = new TokenRegistry();
    }

    function testAddToken() public {
        reg.addToken("USDC", address(0x1234));
        (string memory t, address ca) = reg.tokens(0);
        assertEq(t, "USDC");
        assertEq(ca, address(0x1234));
        assertEq(reg.tokenCount(), 1);
    }

    function testOnlyOwner() public {
        vm.prank(address(0xBeef));
        vm.expectRevert(TokenRegistry.NotOwner.selector);
        reg.addToken("DAI", address(0x1));
    }
}
