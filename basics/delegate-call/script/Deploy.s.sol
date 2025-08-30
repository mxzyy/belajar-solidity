// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {DGProxy, DGv1, IDGv1} from "../src/DG.sol";

contract DGDeploy is Script {
    function run() external {
        // ENV:
        // PRIVATE_KEY : pk deployer yang broadcast
        // PROXY_ADMIN : admin proxy (EOA/kontrak ProxyAdmin)
        // DG_OWNER    : owner logic (user app)
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address proxyAdmin = vm.envAddress("PROXY_ADMIN");
        address dgOwner = vm.envAddress("DG_OWNER");

        vm.startBroadcast(pk);

        // 1) Deploy implementation V1
        DGv1 impl = new DGv1();

        // 2) Siapkan init calldata untuk initialize(owner, initialVar)
        bytes memory initCalldata = abi.encodeWithSelector(
            IDGv1.initialize.selector,
            dgOwner,
            uint256(777) // initial myVar
        );

        // 3) Deploy proxy + panggil initialize via delegatecall
        DGProxy proxy = new DGProxy(address(impl), proxyAdmin, initCalldata);

        vm.stopBroadcast();

        console2.log("DGv1 implementation :", address(impl));
        console2.log("DG Proxy            :", address(proxy));
        console2.log("Proxy Admin         :", proxyAdmin);
        console2.log("DG Owner            :", dgOwner);
    }
}
