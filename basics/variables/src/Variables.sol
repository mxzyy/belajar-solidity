// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Variables {
    // =========================================================
    // STATE VARIABLES - stored permanently on the blockchain
    // =========================================================

    // String - text data
    string public text = "Hello";

    // Unsigned integers - only positive numbers
    uint8 public smallNum = 255;        // max: 2^8 - 1
    uint256 public num = 123;           // max: 2^256 - 1 (uint = uint256)

    // Signed integers - can be negative
    int8 public smallSignedNum = -128;  // range: -128 to 127
    int256 public signedNum = -100;     // range: -(2^255) to 2^255 - 1

    // Boolean - true or false
    bool public flag = true;

    // Address - stores an Ethereum wallet or contract address
    address public owner;

    // Bytes - fixed-size raw byte data
    bytes32 public data = "solidity";   // fixed size, gas efficient
    bytes public dynamicData = "hello"; // dynamic size

    // =========================================================
    // CONSTRUCTOR - runs once when contract is deployed
    // =========================================================

    constructor() {
        // msg.sender here refers to the deployer's address
        owner = msg.sender;
    }

    // =========================================================
    // LOCAL VARIABLES - exist only inside a function, not stored on blockchain
    // =========================================================

    function demoLocalVariables() public pure returns (uint256) {
        uint256 localNum = 456;  // local variable, disappears after function ends
        bool localFlag = false;
        int256 localSigned = -999;

        // Just to use the variables (avoid compiler warnings)
        if (localFlag) {
            localSigned = 0;
        }

        return localNum;
    }

    // =========================================================
    // GLOBAL VARIABLES - provided by the EVM, reflect blockchain state
    // =========================================================

    // Block-related globals
    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;  // current block time in unix seconds
    }

    function getBlockNumber() public view returns (uint256) {
        return block.number;  // current block height
    }

    function getBlockChainId() public view returns (uint256) {
        return block.chainid;  // 1 = mainnet, 11155111 = sepolia, etc.
    }

    // Transaction / message globals
    function getMsgSender() public view returns (address) {
        return msg.sender;  // address that called this function
    }

    function getMsgValue() public payable returns (uint256) {
        return msg.value;  // amount of ETH sent (in wei)
    }

    function getGasPrice() public view returns (uint256) {
        return tx.gasprice;  // gas price of the current transaction
    }

    function getGasLeft() public view returns (uint256) {
        return gasleft();  // remaining gas in this call
    }

    // =========================================================
    // SETTERS & GETTERS for state variables
    // =========================================================

    function setText(string memory y) public {
        text = y;
    }

    function setNum(uint256 x) public {
        num = x;
    }

    function setFlag(bool b) public {
        flag = b;
    }

    function getText() public view returns (string memory) {
        return text;
    }

    function getNum() public view returns (uint256) {
        return num;
    }

    function getFlag() public view returns (bool) {
        return flag;
    }
}
