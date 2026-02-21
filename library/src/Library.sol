pragma solidity ^0.8.20;

import {IERC20} from "./Interfaces.sol";

error SafeTransferFailed();

/* ----------------------- INTERNAL LIBRARIES ----------------------- */
library SafeTransferLib {
    function safeTransferETH(address to, uint256 amount) internal {
        (bool ok, bytes memory data) = to.call{value: amount}("");
        if (!ok) {
            if (data.length > 0) {
                assembly {
                    revert(add(data, 0x20), mload(data))
                }
            }
            revert SafeTransferFailed();
        }
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        bytes memory callData = abi.encodeWithSelector(0xa9059cbb, to, amount);
        _callAndCheck(address(token), callData);
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        bytes memory callData = abi.encodeWithSelector(0x23b872dd, from, to, amount);
        _callAndCheck(address(token), callData);
    }

    function _callAndCheck(address target, bytes memory callData) private {
        (bool ok, bytes memory data) = target.call(callData);
        if (!ok) {
            if (data.length > 0) {
                assembly {
                    revert(add(data, 0x20), mload(data))
                }
            }
            revert SafeTransferFailed();
        }
        if (data.length > 0) {
            require(abi.decode(data, (bool)), "ERC20: transfer returned false");
        }
    }
}

library UintOps {
    function isEven(uint256 x) internal pure returns (bool) {
        return x % 2 == 0;
    }

    function clamp(uint256 x, uint256 minVal, uint256 maxVal) internal pure returns (uint256) {
        if (x < minVal) return minVal;
        if (x > maxVal) return maxVal;
        return x;
    }

    function saturatingAdd(uint256 a, uint256 b) internal pure returns (uint256 c) {
        unchecked {
            c = a + b;
        }
        if (c < a) {
            return type(uint256).max;
        }
    }
}

/* -------------------- EXTERNAL(DEPLOYED) LIBRARY ------------------ */
library PublicMath {
    function mulDiv(uint256 a, uint256 b, uint256 denominator) public pure returns (uint256) {
        require(denominator != 0, "div by zero");
        unchecked {
            return (a * b) / denominator;
        }
    }

    // must be public (bukan external) untuk library
    function sum(uint256[] memory arr) public pure returns (uint256 s) {
        for (uint256 i = 0; i < arr.length; i++) {
            unchecked {
                s += arr[i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeTransferLib, UintOps, PublicMath} from "./Library.sol";
import {IERC20} from "./Interfaces.sol";

/* ---------------------------------------------------------- */
/*         IMPLEMENTASI EXTERNAL & INTERNAL LIBRARY           */
/* ---------------------------------------------------------- */

contract Example {
    using UintOps for uint256;

    IERC20 public immutable token;

    constructor(IERC20 t) {
        token = t;
    }

    function pay(address to, uint256 amount) external {
        // Internal lib: inline, no deploy/link
        uint256 okAmount = amount.clamp(1, 1_000 ether);
        SafeTransferLib.safeTransfer(token, to, okAmount);
    }

    function average(uint256 a, uint256 b) external pure returns (uint256) {
        // External lib: require deploy+link jika dipanggil
        return PublicMath.mulDiv(a + b, 1, 2); // (a+b)/2 dibulatkan ke bawah
    }
}
