# HelloWorld Smart Contract

A simple smart contract written in Solidity using the Foundry framework. This project serves as a basic introduction to Ethereum smart contract development.

## About

HelloWorld is a minimal smart contract that stores a public string variable `greet` containing "Hello World!". The project includes:

- **Smart Contract** - Main contract in `src/HelloWorld.sol`
- **Unit Tests** - Test suite in `test/HelloWorld.t.sol`
- **Deployment Script** - Deployment automation in `script/Deploy.s.sol`

## Tech Stack

- **Solidity** `^0.8.26`
- **Foundry** (Forge, Anvil, Cast)

## Project Structure

```
hello-world/
├── src/
│   └── HelloWorld.sol      # Main contract
├── script/
│   └── Deploy.s.sol        # Deployment script
├── test/
│   └── HelloWorld.t.sol    # Unit tests
├── lib/
│   └── forge-std/          # Foundry standard library
└── foundry.toml            # Foundry configuration
```

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
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "greet()" --rpc-url http://127.0.0.1:8545 | cast --to-ascii
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
