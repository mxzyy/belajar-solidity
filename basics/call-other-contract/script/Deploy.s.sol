// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {
    TokenSpender,
    GenericCaller,
    UpgradeableProxy,
    OracleReader,
    SendWrapper,
    TransferWrapper,
    PaymentProcessor,
    ChildFactory,
    SafeERC20Caller
} from "src/COC.sol";
import {LogicV1} from "test/COC.t.sol"; // Reuse simple logic impl for proxy demo; replace with your own in production

contract Deploy is Script {
    struct Deployed {
        TokenSpender tokenSpender;
        GenericCaller genericCaller;
        OracleReader oracleReader;
        SendWrapper sendWrapper;
        TransferWrapper transferWrapper;
        PaymentProcessor paymentProcessor;
        ChildFactory childFactory;
        SafeERC20Caller safeERC20Caller;
        address proxy;
        address impl;
    }

    function run() external returns (Deployed memory d) {
        // Use anvil or real key: forge script ... --rpc-url ... --broadcast --private-key $PRIVATE_KEY
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        d.tokenSpender = new TokenSpender();
        d.genericCaller = new GenericCaller();
        d.oracleReader = new OracleReader();
        d.sendWrapper = new SendWrapper();
        d.transferWrapper = new TransferWrapper();
        d.paymentProcessor = new PaymentProcessor();
        d.childFactory = new ChildFactory();
        d.safeERC20Caller = new SafeERC20Caller();

        // Minimal upgradeable proxy demo (admin = msg.sender)
        LogicV1 impl = new LogicV1();
        bytes memory initData; // none
        UpgradeableProxy proxy = new UpgradeableProxy(msg.sender, address(impl), initData);
        d.impl = address(impl);
        d.proxy = address(proxy);

        vm.stopBroadcast();

        _log(d);
    }

    function _log(Deployed memory d) internal pure {
        console2.log("==== Deployed Addresses ====");
        console2.log("TokenSpender         ", address(d.tokenSpender));
        console2.log("GenericCaller        ", address(d.genericCaller));
        console2.log("OracleReader         ", address(d.oracleReader));
        console2.log("SendWrapper          ", address(d.sendWrapper));
        console2.log("TransferWrapper      ", address(d.transferWrapper));
        console2.log("PaymentProcessor     ", address(d.paymentProcessor));
        console2.log("ChildFactory         ", address(d.childFactory));
        console2.log("SafeERC20Caller      ", address(d.safeERC20Caller));
        console2.log("Logic Impl (V1)      ", d.impl);
        console2.log("Upgradeable Proxy     ", d.proxy);
        console2.log("===========================");
    }
}
