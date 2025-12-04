// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DeployTokenScript} from "../script/Deploy.s.sol";
import {Token} from "../src/Token.sol";

contract CounterTest is Test {
    function _deploy() internal returns (Token token, address deployer) {
        DeployTokenScript deployScript = new DeployTokenScript();
        deployScript.run();
        return (deployScript.token(), deployScript.deployer());
    }

    function testTokenDeployment() public {
        (Token token, ) = _deploy();
        address tokenAddress = address(token);
        console.log("Deployed Token address:", tokenAddress);
        assert(tokenAddress != address(0));
    }

    function testInitialSupply() public {
        (Token token, ) = _deploy();
        uint256 initialSupply = token.totalSupply();
        console.log("Initial Token Supply:", initialSupply);
        assert(initialSupply == 1_000_000 * 10 ** token.decimals());
    }

    function testTransfer() public {
        (Token token, address deployer) = _deploy();
        uint256 initialAllocation = 1_000 * 10 ** token.decimals();
        vm.startPrank(deployer);
        token.transfer(address(this), initialAllocation);
        vm.stopPrank();

        address recipient = address(0x123);
        uint256 transferAmount = 10 * 10 ** token.decimals();

        uint256 initialSenderBalance = token.balanceOf(address(this));
        console.log("Initial Sender Balance:", initialSenderBalance);
        uint256 initialRecipientBalance = token.balanceOf(recipient);
        console.log("Initial Recipient Balance:", initialRecipientBalance);

        token.transfer(recipient, transferAmount);

        uint256 finalSenderBalance = token.balanceOf(address(this));
        uint256 finalRecipientBalance = token.balanceOf(recipient);

        assert(finalSenderBalance == initialSenderBalance - transferAmount);
        assert(finalRecipientBalance == initialRecipientBalance + transferAmount);
    }

    function testAllowance() public {
        (Token token, address deployer) = _deploy();
        uint256 initialAllocation = 1_000 * 10 ** token.decimals();
        vm.startPrank(deployer);
        token.transfer(address(this), initialAllocation);
        vm.stopPrank();

        address spender = address(0x456);
        uint256 approveAmount = 500 * 10 ** token.decimals();

        token.approve(spender, approveAmount);
        uint256 allowance = token.allowance(address(this), spender);

        console.log("Allowance for spender:", allowance);
        assert(allowance == approveAmount);
    }
}
