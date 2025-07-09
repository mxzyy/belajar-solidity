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
$ forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

### Cast Test Bool

```shell
$ cast call 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 "boo()" --rpc-url http://127.0.0.1:8545 | cast --to-dec

$ cast call 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 "u8()" --rpc-url http://127.0.0.1:8545 | cast --to-dec

$ cast call 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 "u256()" --rpc-url http://127.0.0.1:8545 | cast --to-dec

$ cast call 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 "u()" --rpc-url http://127.0.0.1:8545 | cast --to-dec

$ cast call 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 "i8()" --rpc-url http://127.0.0.1:8545 | cast --to-dec
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
