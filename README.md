# phoneToken - Cross-Chain ERC20 Token with Chainlink CCIP

`phoneToken` is an ERC20 token designed to support cross-chain bridging using Chainlink's Cross-Chain Interoperability Protocol (CCIP). Built with Solidity and deployed via Foundry, it includes features like minting/burning, a fee mechanism, whitelisting, and monthly mint limits, making it a versatile token for cross-chain applications.

## Token Features

- **ERC20 Compliance**: Standard ERC20 functionality with 18 decimals.
- **Max Supply**: 420,069,000,000 `ph` tokens.
- **Initial Mint**: 14% of max supply minted to the admin on deployment.
- **Monthly Mint Limit**: 1% of max supply can be minted per month.
- **Burnable**: Tokens can be burned by addresses with the `BURNER_ROLE`.
- **Fee Mechanism**: 1% transfer fee (100 basis points) applied unless sender or recipient is whitelisted.
- **Whitelist**: Whitelisted addresses bypass the transfer fee.
- **Access Control**: Uses OpenZeppelin's `AccessControl` with roles (`MINTER_ROLE`, `BURNER_ROLE`, `DEFAULT_ADMIN_ROLE`).
- **Cross-Chain Support**: Integrates with Chainlink CCIP for bridging via a `BurnMintTokenPool`.

## Prerequisites

To run this project, you'll need the following tools installed:

- **Foundry**: A fast Ethereum development toolkit.
- **Git**: For cloning the repository.
- **Node.js**: Optional, for additional package management if needed.
- **An Ethereum-compatible wallet**: With testnet funds (e.g., Sepolia ETH, Arbitrum Sepolia ETH, BSC Testnet BNB).
- **RPC Endpoints**: Access to testnet RPCs for supported chains (Ethereum Sepolia, Arbitrum Sepolia, BSC Testnet).

## Setup and Deployment Instructions

Follow these steps to set up, deploy, and configure the `phoneToken` project.

### 1. Install Foundry

Install Foundry by running the following command:

```bash
curl -L https://foundry.paradigm.xyz | bash
```


## 2. Update Foundry to the Latest Version

```bash
foundryup
```

## 3. Verify the Installation

```bash
forge --version
```

## 4. Clone the Repository and Install Dependencies

```bash
git clone <repository-url>
cd phoneToken
forge install
```

This will fetch OpenZeppelin contracts, Chainlink CCIP contracts, and other dependencies listed in `lib/`.

## 5. Set Up a Foundry Account

Foundry uses accounts to manage private keys securely. To add your wallet to Foundry, use the `cast wallet import` command:

```bash
cast wallet import defaultKey --private-key <your-private-key>
```

Replace `<your-private-key>` with your actual private key. This command stores the key in Foundry's keystore (typically at `~/.foundry/keystore/`) under the alias `defaultKey`. You’ll be prompted to set a password—make sure to remember it, as it’s required for signing transactions later.


## 6. Compile the Contracts

Compile the Solidity contracts:

```bash
forge build
```

Deploy using:

```bash
forge script script/deploy.s.sol:Deploy --rpc-url https://sepolia.infura.io/v3/<your-infura-key> --account defaultKey --sender YOURAddress --broadcast
```

You’ll be prompted for the keystore password. This script:

- Deploys the `phoneToken` contract.
- Deploys a `BurnMintTokenPool` for CCIP bridging.
- Grants `MINTER_ROLE` and `BURNER_ROLE` to the pool.
- Sets up the CCIP admin and pool in the `TokenAdminRegistry`.

Check the console output for the deployed Token Address and Pool Address.

Repeat this step for other chains (e.g., Arbitrum Sepolia, BSC Testnet) by changing the RPC URL:

```bash
forge script script/deploy.s.sol:Deploy --rpc-url https://sepolia-rollup.arbitrum.io/rpc --account defaultKey --sender YOURAddress --broadcast

forge script script/deploy.s.sol:Deploy --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545 --account defaultKey --sender YOURAddress --broadcast
```

Run configuration script:

```bash
forge script script/configure.s.sol:Configure --rpc-url https://sepolia.infura.io/v3/<your-infura-key> --account defaultKey --sender YOURAddress --broadcast
```

This script:

- Identifies unconfigured remote chains (e.g., Arbitrum Sepolia, BSC Testnet).
- Calls `applyChainUpdates` on the pool to link it with remote pools and tokens.

Repeat for each deployed chain:

```bash
forge script script/configure.s.sol:Configure --rpc-url https://sepolia-rollup.arbitrum.io/rpc --account defaultKey --sender YOURAddress --broadcast

forge script script/configure.s.sol:Configure --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545 --account defaultKey --sender YOURAddress --broadcast
```

Configuration logs show remote chains added successfully.

## . Interact with Contracts Using `cast`

```bash
cast call <token-address> "totalSupply()" --rpc-url https://sepolia.infura.io/v3/<your-infura-key>

cast call <pool-address> "getSupportedChains()" --rpc-url https://sepolia.infura.io/v3/<your-infura-key>
```

---

## Adding a New Chain in the Future

To extend `phoneToken` to a new chain (e.g., `UnichainSepolia`), follow these steps:

```solidity
networks.push(NetworkDetails({
    name: "UnichainSepolia",
    chainId: 1301,
    chainSelector: helperConfig.getUnichainSepoliaConfig().chainSelector,
    routerAddress: helperConfig.getUnichainSepoliaConfig().router,
    linkAddress: helperConfig.getUnichainSepoliaConfig().link,
    rmnProxyAddress: helperConfig.getUnichainSepoliaConfig().rmnProxy,
    tokenAdminRegistryAddress: helperConfig.getUnichainSepoliaConfig().tokenAdminRegistry,
    registryModuleOwnerCustomAddress: helperConfig.getUnichainSepoliaConfig().registryModuleOwnerCustom,
    token: address(0), // Updated after deployment
    pool: address(0)   // Updated after deployment
}));
```

Update `HelperConfig.s.sol` with the new chain's configuration if not already present.

### 2. Deploy to the New Chain

Deploy the token and pool to the new chain:

```bash
forge script script/deploy.s.sol:Deploy --rpc-url https://rpc.unichain-sepolia.example --account defaultKey --sender YOURAddress --broadcast
```

Note the new token and pool addresses from the console output.

### 3. Update Existing Chains

Update the `networks` array in `BaseScript.s.sol` with the new chain's deployed addresses (replace the `address(0)` placeholders).

Reconfigure existing pools to recognize the new chain:

```bash
forge script script/configure.s.sol:Configure --rpc-url https://sepolia.infura.io/v3/<your-infura-key> --account defaultKey --sender YOURAddress --broadcast

forge script script/configure.s.sol:Configure --rpc-url https://sepolia-rollup.arbitrum.io/rpc --account defaultKey --sender YOURAddress --broadcast

forge script script/configure.s.sol:Configure --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545 --account defaultKey --sender YOURAddress --broadcast

forge script script/configure.s.sol:Configure --rpc-url https://rpc.unichain-sepolia.example --account defaultKey --sender YOURAddress --broadcast
```

Verify supported chains:

```bash
cast call <pool-address> "getSupportedChains()" --rpc-url https://rpc.unichain-sepolia.example
```

---

## Troubleshooting

- **Deployment Fails:** Check gas limits, RPC connectivity, and sufficient testnet funds.
- **Configuration Fails:** Verify chain selectors, pool addresses, and router compatibility in logs.
- **Keystore Issues:** Ensure the correct password and account alias are used.
- **Logs:** Use `console.log` outputs in scripts to debug.

---

## License

This project is licensed under the MIT License - see the SPDX-License-Identifier: MIT in the source files.

---
