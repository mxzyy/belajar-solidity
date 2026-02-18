# Counter Smart Contract

A simple counter smart contract written in Solidity using the Foundry framework. This project demonstrates basic state management and function interactions in Ethereum smart contract development.

## About

Counter is a minimal smart contract that stores a public `uint256` state variable `count` and exposes functions to read and modify it. The project includes:

- **Smart Contract** - Main contract in `src/FirstApplication.sol`
- **Unit Tests** - Test suite in `test/FirstApplication.t.sol`
- **Deployment Script** - Deployment automation in `script/Deploy.s.sol`

## Tech Stack

- **Solidity** `^0.8.26`
- **Foundry** (Forge, Anvil, Cast)

## Project Structure

```
first-application/
├── src/
│   └── FirstApplication.sol    # Main contract (Counter)
├── script/
│   └── Deploy.s.sol            # Deployment script
├── test/
│   └── FirstApplication.t.sol  # Unit tests
├── lib/
│   └── forge-std/              # Foundry standard library
└── foundry.toml                # Foundry configuration
```

## Contract Functions

| Function | Type | Description |
|----------|------|-------------|
| `get()` | `view` | Returns the current count value |
| `inc()` | write | Increments count by 1 |
| `dec()` | write | Decrements count by 1 (reverts if count is 0) |

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
# Get current count
cast call <CONTRACT_ADDRESS> "get()" --rpc-url http://127.0.0.1:8545

# Increment count
cast send <CONTRACT_ADDRESS> "inc()" --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://127.0.0.1:8545

# Decrement count
cast send <CONTRACT_ADDRESS> "dec()" --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://127.0.0.1:8545
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
