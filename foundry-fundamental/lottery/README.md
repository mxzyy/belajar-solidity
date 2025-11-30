## Raffe Contract Foundry

**Raffle Contrat implemented from Cyfrin Updraft Foundry Fundamentals Final Section**

A raffle (or lottery) is a scheme where all participants contribute money to a single prize pool, and a random winner is selected to receive the entire pool. 

It is implemented as an Ethereum smart contract and uses Chainlink VRF and Chainlink Automation to automate the raffle.

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

* https://book.getfoundry.sh/
* https://docs.chain.link/vrf
* https://docs.chain.link/chainlink-automation


## Usage

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

### Anvil

```shell
$ anvil
```

### Deploy (Local)

NOTE: Pastiin SubsAPI di VRF Mocks menggunakan blockhash(block.number)

```shell
$ forge script script/DeployRaffle.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --account acc-1 --sender 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
```

### Cast

```shell
$ 
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
