// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {ETHSenderPlayground, ReceiverMinimal, ReceiverExpensive} from "../src/Send.sol";

contract DeployETHSender is Script {
    function run() external {
        // ENV wajib: PRIVATE_KEY
        uint256 pk = vm.envUint("PRIVATE_KEY");

        // ENV opsional: INITIAL_DEPOSIT_WEI (default 0)
        uint256 initialDeposit = _readOptionalUint("INITIAL_DEPOSIT_WEI", 0);

        vm.startBroadcast(pk);

        ETHSenderPlayground p = new ETHSenderPlayground();
        ReceiverMinimal rMin = new ReceiverMinimal();
        ReceiverExpensive rExp = new ReceiverExpensive();

        if (initialDeposit > 0) {
            // Setor dana awal ke playground (agar bisa langsung tes kirim ETH)
            p.deposit{value: initialDeposit}();
        }

        console2.log("ETHSenderPlayground:", address(p));
        console2.log("ReceiverMinimal    :", address(rMin));
        console2.log("ReceiverExpensive  :", address(rExp));
        console2.log("Deposited (wei)    :", initialDeposit);

        vm.stopBroadcast();
    }

    function _readOptionalUint(string memory key, uint256 fb) internal returns (uint256) {
        try vm.envUint(key) returns (uint256 v) {
            return v;
        } catch {
            return fb;
        }
    }
}
