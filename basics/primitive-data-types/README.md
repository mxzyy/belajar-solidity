# Primitives Smart Contract

A simple smart contract written in Solidity using the Foundry framework. This project demonstrates all primitive data types available in Solidity.

## About

Primitives is a minimal smart contract that showcases Solidity's built-in primitive data types including `bool`, `uint`, `int`, `address`, and `bytes1`, along with their default values. The project includes:

- **Smart Contract** - Main contract in `src/Primitives.sol`
- **Unit Tests** - Test suite in `test/Primitives.t.sol`
- **Deployment Script** - Deployment automation in `script/Deploy.s.sol`
- **Test Script** - Auto deploy & call all getters via `test.sh`

## Tech Stack

- **Solidity** `^0.8.26`
- **Foundry** (Forge, Anvil, Cast)

## Project Structure

```
primitive-data-types/
├── src/
│   └── Primitives.sol      # Main contract
├── script/
│   └── Deploy.s.sol        # Deployment script
├── test/
│   └── Primitives.t.sol    # Unit tests
├── lib/
│   └── forge-std/          # Foundry standard library
├── test.sh                 # Auto deploy & cast test script
└── foundry.toml            # Foundry configuration
```

## Contract Variables

| Variable | Type | Default Value |
|----------|------|---------------|
| `boo` | `bool` | `true` |
| `u8` | `uint8` | `1` |
| `u256` | `uint256` | `456` |
| `u` | `uint256` | `123` |
| `i8` | `int8` | `-1` |
| `i256` | `int256` | `456` |
| `i` | `int256` | `-123` |
| `minInt` | `int256` | `type(int256).min` |
| `maxInt` | `int256` | `type(int256).max` |
| `addr` | `address` | `0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c` |
| `a` | `bytes1` | `0xb5` |
| `b` | `bytes1` | `0x56` |
| `defaultBoo` | `bool` | `false` |
| `defaultUint` | `uint256` | `0` |
| `defaultInt` | `int256` | `0` |
| `defaultAddr` | `address` | `0x0000000000000000000000000000000000000000` |

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

### Auto Deploy & Cast Test

Jalankan `test.sh` untuk otomatis start Anvil, deploy contract, dan test semua public variables:

```bash
bash test.sh
```

## Command Reference

| Command | Description |
|---------|-------------|
| `forge build` | Compile contracts |
| `forge test` | Run unit tests |
| `forge fmt` | Format Solidity code |
| `anvil --chain-id 1337` | Start local blockchain |
| `forge script script/Deploy.s.sol --rpc-url <RPC> --private-key <KEY> --broadcast` | Deploy contract |
| `bash test.sh` | Auto deploy & test all getters |

## Documentation

- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity Docs](https://docs.soliditylang.org/)

## License

MIT
