// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*
Layout & alasan p (slot index):
- p ditentukan oleh URUTAN deklarasi state variable (setelah memperhitungkan packing).
- mapping TIDAK bisa dipack => selalu ambil 1 slot utuh untuk "head"-nya (basis hashing).
- dynamic array (T[]) juga ambil 1 slot untuk "head" (menyimpan length).
- variable berikutnya geser ke p+1, dst.

Di kontrak ini:
  p=0 -> mapping(address => uint256) bal
  p=1 -> uint256[] arr
  p=2 -> mapping(address => uint256[]) logs
*/

import "forge-std/console2.sol";

contract SlotsDebug {
    mapping(address => uint256) public bal; // p = 0
    uint256[] public arr; // p = 1 (menyimpan length di slot 1)
    mapping(address => uint256[]) public logs; // p = 2

    // Isi contoh data biar ada yang dibaca
    function seed(address a) external {
        bal[a] = 333;
        arr.push(111);
        arr.push(222);
        logs[a].push(7);
        logs[a].push(8);
        logs[a].push(9);
    }

    /* ---------------- Helper murni (return nilai ke caller) ---------------- */

    // Helper untuk verifikasi di Chisel
    function slotOf_bal(address a) public pure returns (bytes32) {
        return keccak256(abi.encode(a, uint256(0))); // p=0 untuk bal
    }

    function preimage_bal(address a) public pure returns (bytes memory) {
        // Ini bytes yang DI-HASH:
        //  - 32B: pad32(address a)  (12B nol + 20B address)
        //  - 32B: pad32(uint256(0)) (32B nol karena p=0)
        return abi.encode(a, uint256(0));
    }

    // Info letak p (slot index) secara eksplisit
    function layoutSlots() external pure returns (uint256 pBal, uint256 pArr, uint256 pLogs) {
        return (0, 1, 2);
    }

    // mapping: slot(m[key]) = keccak256(abi.encode(key, uint256(p)))
    function slotBalOf(address a) public pure returns (bytes32) {
        return keccak256(abi.encode(a, uint256(0)));
    }

    // dynamic array head: length disimpan di slot p; data base = keccak256(abi.encode(p))
    function baseArr() public pure returns (bytes32) {
        return keccak256(abi.encode(uint256(1)));
    }

    // mapping -> dynamic array:
    // head = keccak256(abi.encode(key, p))
    // base = keccak256(abi.encode(head))
    function headLogsOf(address a) public pure returns (bytes32) {
        return keccak256(abi.encode(a, uint256(2)));
    }

    function baseLogsOf(address a) public pure returns (bytes32) {
        return keccak256(abi.encode(headLogsOf(a)));
    }

    // sload mentah (baca 1 slot)
    function readU256(uint256 slot_) public view returns (uint256 val) {
        assembly {
            val := sload(slot_)
        }
    }

    /* --------------- “Full print” via console2 (untuk forge test/script) --------------- */

    function debugAll(address a) external view {
        // 1) Cetak p (kenapa p=0/1/2)
        console2.log("== Layout p-index (urut deklarasi) ==");
        console2.log("p(bal)  = 0  // mapping tidak bisa di-pack, jadi ambil slot utuh pertama");
        console2.log("p(arr)  = 1  // dynamic array: slot 1 menyimpan length");
        console2.log("p(logs) = 2  // mapping lain, geser ke slot berikutnya");

        // 2) mapping(address=>uint): slot & value
        bytes32 sBal = slotBalOf(a);
        uint256 sBalU = uint256(sBal);
        uint256 balVal;
        assembly {
            balVal := sload(sBalU)
        }

        console2.log("== mapping bal[a] ==");
        console2.log("slot(bal[a]) = keccak256(abi.encode(a, p=0)):");
        console2.logBytes32(sBal);
        console2.log("value @slot   =", balVal);

        // 3) uint256[] arr: length & base & elemen
        uint256 lenArr;
        assembly {
            lenArr := sload(1)
        }
        bytes32 bArr = baseArr();
        uint256 bArrU = uint256(bArr);
        uint256 arr0;
        assembly {
            arr0 := sload(bArrU)
        }
        uint256 arr1;
        assembly {
            arr1 := sload(add(bArrU, 1))
        }

        console2.log("== uint256[] arr ==");
        console2.log("arr.length @ p=1 =", lenArr);
        console2.log("base(arr) = keccak256(abi.encode(p=1)):");
        console2.logBytes32(bArr);
        console2.log("arr[0] @ base+0  =", arr0);
        console2.log("arr[1] @ base+1  =", arr1);

        // 4) mapping(address=>uint[]) logs: head, length, base, elemen
        bytes32 hLogs = headLogsOf(a);
        uint256 hLogsU = uint256(hLogs);
        uint256 lenLogs;
        assembly {
            lenLogs := sload(hLogsU)
        }

        bytes32 bLogs = baseLogsOf(a);
        uint256 bLogsU = uint256(bLogs);
        uint256 logs0;
        assembly {
            logs0 := sload(bLogsU)
        }
        uint256 logs1;
        assembly {
            logs1 := sload(add(bLogsU, 1))
        }
        uint256 logs2;
        assembly {
            logs2 := sload(add(bLogsU, 2))
        }

        console2.log("== mapping(address=>uint[]) logs ==");
        console2.log("head = keccak256(abi.encode(a, p=2)):");
        console2.logBytes32(hLogs);
        console2.log("logs[a].length @ head =", lenLogs);
        console2.log("base = keccak256(abi.encode(head)):");
        console2.logBytes32(bLogs);
        console2.log("logs[a][0] @ base+0 =", logs0);
        console2.log("logs[a][1] @ base+1 =", logs1);
        console2.log("logs[a][2] @ base+2 =", logs2);
    }
}
