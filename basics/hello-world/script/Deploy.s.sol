// script/Deploy.s.sol
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/HelloWorld.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();
        HelloWorld helloWorld = new HelloWorld();
        console.log("Deployed to:", address(helloWorld));
        vm.stopBroadcast();
    }
}