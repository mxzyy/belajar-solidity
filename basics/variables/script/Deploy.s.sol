// script/Deploy.s.sol
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/Variables.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();
        Variables variables = new Variables();
        console.log("Deployed to:", address(variables));
        vm.stopBroadcast();
    }
}