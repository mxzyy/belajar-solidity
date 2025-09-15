// SlotsDemo.sol
pragma solidity ^0.8.24;

contract SlotsDemo {
    // Layout (slot index p):
    // p=0 -> mapping(address => uint256) bal
    // p=1 -> uint256[] arr
    // p=2 -> mapping(address => uint256[]) logs

    mapping(address => uint256) public bal; // p = 0
    uint256[] public arr; // p = 1
    mapping(address => uint256[]) public logs; // p = 2

    // Isi data contoh
    function seed(address a) external {
        bal[a] = 333;
        arr.push(111);
        arr.push(222);
        logs[a].push(7);
        logs[a].push(8);
        logs[a].push(9);
    }

    /* ------------------- Slot calculator helpers ------------------- */
    // mapping: slot(m[key]) = keccak256(abi.encode(key, p))
    function slotBal(address a) external pure returns (uint256) {
        return uint256(keccak256(abi.encode(a, uint256(0))));
    }

    // dynamic array head: length disimpan di slot p
    function slotArrLength() external pure returns (uint256) {
        return 1;
    }
    // data arr mulai di base = keccak256(abi.encode(p))

    function baseArr() external pure returns (uint256) {
        return uint256(keccak256(abi.encode(uint256(1))));
    }

    // mapping -> dynamic array:
    // head = keccak256(abi.encode(key, p))  (menyimpan length)
    // data base = keccak256(abi.encode(head))
    function headLogs(address a) external pure returns (uint256) {
        return uint256(keccak256(abi.encode(a, uint256(2))));
    }

    function baseLogs(address a) external pure returns (uint256) {
        uint256 head = uint256(keccak256(abi.encode(a, uint256(2))));
        return uint256(keccak256(abi.encode(head)));
    }

    // baca storage mentah
    function sloadU256(uint256 slot_) external view returns (uint256 val) {
        assembly {
            val := sload(slot_)
        }
    }
}
