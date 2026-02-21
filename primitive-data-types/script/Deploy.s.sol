// script/Deploy.s.sol
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/Primitives.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();
        Primitives primitives = new Primitives();
        console.log("Deployed to:", address(primitives));
        vm.stopBroadcast();
    }
}