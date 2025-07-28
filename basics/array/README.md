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
$ forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --account acc-1 --sender 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
```

### Cast

```shell
$ cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
"add(string,address)" alice 0x000000000000000000000000000000000000aAaA \
--rpc-url http://127.0.0.1:8545 \
--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

$ cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
"getUserCount()(uint256)" \
--rpc-url http://127.0.0.1:8545

$ cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
"get(uint256)(string,address)" 0 \
--rpc-url http://127.0.0.1:8545

$ cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
"getByKey(string)(address)" alice \
--rpc-url http://127.0.0.1:8545


```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
``` 