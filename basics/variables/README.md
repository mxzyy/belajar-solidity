## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Anvil

```shell
$ anvil --chain-id 1337
```

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```


### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3  "getStr()" --rpc-url http://127.0.0.1:8545 | cast --to-ascii

$ cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "setSomethingText(string)" "walawe"   --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80   --rpc-url http://127.0.0.1:8545

$ cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3  "getNum()" --rpc-url http://127.0.0.1:8545 | cast --to-dec

$ cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "setSomethingNum(uint256)" 32390209   --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80   --rpc-url http://127.0.0.1:8545
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
