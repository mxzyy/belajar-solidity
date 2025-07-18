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
$ forge test -vv
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

### Deploy use cast account
```shell
forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --account acc-1 --sender 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
```

### Cast import wallet

```shell
cast wallet import acc-1 --interactive
```

```shell
cast call <Contract Address> "for_loop()" --rpc-url http://127.0.0.1:8545 | cast --to-dec

cast call <Contract Address> "while_loop()" --rpc-url http://127.0.0.1:8545 | cast --to-dec

cast call <Contract Address> "do_while()" --rpc-url http://127.0.0.1:8545 | cast --to-dec
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
