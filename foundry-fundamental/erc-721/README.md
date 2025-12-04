# ERC-721 Example

Non-fungible tokens follow the ERC-721 standard, giving each token a unique identifier and ownership tracking that can be transferred while preserving provenance.

### NFT Contract

- ERC721 named `MyNFT` with symbol `MNFT`.
- `mint(address to, string tokenUri)` increments an internal counter, mints the token, stores the tokenURI, and returns the new tokenId.

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Deploy

```shell
$ forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --account acc-1 --sender 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
```

### Mint via Cast

```shell
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  "mint(address,string)" \
  0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc \
  "ipfs://bafybeidgbhucjcqslrcigdh527f5rg462gvg2oamoxr2fqiqcw6yddc46i/403" \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6

cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 \
  "mint(address,string)" \
  0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc \
  "https://remilio.org/remilio/json/9903" \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6

```
