// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console2 as console} from "forge-std/Script.sol";
import {simpleEscrow} from "../src/Constructor.sol";

contract DeployScript is Script {
    // Alamat demonstrasi (akan di-generate deterministic oleh foundry)
    address private payer = vm.addr(0xB);
    address private payee = vm.addr(0xC);
    uint256 private constant WAIT = 5 minutes;

    function run() external {
        // Ambil private-key deployer dari env (export PRIVATE_KEY=0x...)
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        // Kirim 1 ETH sebagai seed ke kontrak saat deploy
        simpleEscrow sc = new simpleEscrow{value: 1 ether}(payer, payee, WAIT);

        console.log("SimpleEscrow deployed at:", address(sc));
        console.log("  payer :", payer);
        console.log("  payee :", payee);
        console.log("  release after:", WAIT);

        vm.stopBroadcast();
    }
}
