# Variables Smart Contract

A simple smart contract written in Solidity using the Foundry framework. This project demonstrates how to use state variables, local variables, and global variables in Solidity.

## About

Variables is a minimal smart contract that stores public state variables (`text` and `num`) and exposes functions to read and modify them. It also demonstrates the use of global variables like `block.timestamp`. The project includes:

- **Smart Contract** - Main contract in `src/Variables.sol`
- **Unit Tests** - Test suite in `test/Variables.t.sol`
- **Deployment Script** - Deployment automation in `script/Deploy.s.sol`

## Tech Stack

- **Solidity** `^0.8.26`
- **Foundry** (Forge, Anvil, Cast)

## Project Structure

```
variables/
├── src/
│   └── Variables.sol      # Main contract
├── script/
│   └── Deploy.s.sol       # Deployment script
├── test/
│   └── Variables.t.sol    # Unit tests
├── lib/
│   └── forge-std/         # Foundry standard library
└── foundry.toml           # Foundry configuration
```

## Contract Functions

| Function | Type | Description |
|----------|------|-------------|
| `getStr()` | `view` | Returns the current text value |
| `getNum()` | `view` | Returns the current num value |
| `setSomethingText(string)` | write | Sets the text state variable |
| `setSomethingNum(uint256)` | write | Sets the num state variable |
| `getTimeStamp()` | `view` | Returns the current block timestamp |
| `getNow()` | `view` | Returns the current block timestamp |

## Prerequisites

Install Foundry:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

## Usage

### Build

```bash
forge build
```

### Test

```bash
forge test
```

### Run Local Blockchain

```bash
anvil --chain-id 1337
```

### Deploy to Anvil

```bash
forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

### Call Contract

```bash
# Get current text
cast call <CONTRACT_ADDRESS> "getStr()" --rpc-url http://127.0.0.1:8545 | cast --to-ascii

# Set text
cast send <CONTRACT_ADDRESS> "setSomethingText(string)" "walawe" --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://127.0.0.1:8545

# Get current num
cast call <CONTRACT_ADDRESS> "getNum()" --rpc-url http://127.0.0.1:8545 | cast --to-dec

# Set num
cast send <CONTRACT_ADDRESS> "setSomethingNum(uint256)" 32390209 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://127.0.0.1:8545
```

## Command Reference

| Command | Description |
|---------|-------------|
| `forge build` | Compile contracts |
| `forge test` | Run unit tests |
| `forge fmt` | Format Solidity code |
| `anvil --chain-id 1337` | Start local blockchain |
| `forge script script/Deploy.s.sol --rpc-url <RPC> --private-key <KEY> --broadcast` | Deploy contract |

## Documentation

- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity Docs](https://docs.soliditylang.org/)

## License

MIT
