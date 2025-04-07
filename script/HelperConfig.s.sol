// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        uint64 chainSelector;
        address router;
        address rmnProxy;
        address tokenAdminRegistry;
        address registryModuleOwnerCustom;
        address link;
        uint256 confirmations;
        string nativeCurrencySymbol;
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getEthereumSepoliaConfig();
        } else if (block.chainid == 421614) {
            activeNetworkConfig = getArbitrumSepolia();
        } else if (block.chainid == 43113) {
            activeNetworkConfig = getAvalancheFujiConfig();
        } else if (block.chainid == 84532) {
            activeNetworkConfig = getBaseSepoliaConfig();
        } else if (block.chainid == 97) {
            activeNetworkConfig = getBSCTestnetConfig();
        } else if (block.chainid == 1301) {
        activeNetworkConfig = getUnichainSepoliaConfig();
    }
    }

    function getEthereumSepoliaConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethereumSepoliaConfig = NetworkConfig({
            chainSelector: 16015286601757825753,
            router: 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59,
            rmnProxy: 0xba3f6251de62dED61Ff98590cB2fDf6871FbB991,
            tokenAdminRegistry: 0x95F29FEE11c5C55d26cCcf1DB6772DE953B37B82,
            registryModuleOwnerCustom: 0x62e731218d0D47305aba2BE3751E7EE9E5520790,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            confirmations: 2,
            nativeCurrencySymbol: "ETH"
        });
        return ethereumSepoliaConfig;
    }

    function getArbitrumSepolia() public pure returns (NetworkConfig memory) {
        NetworkConfig memory arbitrumSepoliaConfig = NetworkConfig({
            chainSelector: 3478487238524512106,
            router: 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165,
            rmnProxy: 0x9527E2d01A3064ef6b50c1Da1C0cC523803BCFF2,
            tokenAdminRegistry: 0x8126bE56454B628a88C17849B9ED99dd5a11Bd2f,
            registryModuleOwnerCustom: 0xE625f0b8b0Ac86946035a7729Aba124c8A64cf69,
            link: 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E,
            confirmations: 2,
            nativeCurrencySymbol: "ETH"
        });
        return arbitrumSepoliaConfig;
    }

    function getAvalancheFujiConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory avalancheFujiConfig = NetworkConfig({
            chainSelector: 14767482510784806043,
            router: 0xF694E193200268f9a4868e4Aa017A0118C9a8177,
            rmnProxy: 0xAc8CFc3762a979628334a0E4C1026244498E821b,
            tokenAdminRegistry: 0xA92053a4a3922084d992fD2835bdBa4caC6877e6,
            registryModuleOwnerCustom: 0x97300785aF1edE1343DB6d90706A35CF14aA3d81,
            link: 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846,
            confirmations: 2,
            nativeCurrencySymbol: "AVAX"
        });
        return avalancheFujiConfig;
    }

    function getBaseSepoliaConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory baseSepoliaConfig = NetworkConfig({
            chainSelector: 10344971235874465080,
            router: 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93,
            rmnProxy: 0x99360767a4705f68CcCb9533195B761648d6d807,
            tokenAdminRegistry: 0x736D0bBb318c1B27Ff686cd19804094E66250e17,
            registryModuleOwnerCustom: 0x8A55C61227f26a3e2f217842eCF20b52007bAaBe,
            link: 0xE4aB69C077896252FAFBD49EFD26B5D171A32410,
            confirmations: 2,
            nativeCurrencySymbol: "ETH"
        });
        return baseSepoliaConfig;
    }
    function getBSCTestnetConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory bscTestnetConfig = NetworkConfig({
            chainSelector: 13264668187771770619,
            router: 0xE1053aE1857476f36A3C62580FF9b016E8EE8F6f,
            rmnProxy: 0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D,
            tokenAdminRegistry: 0xF8f2A4466039Ac8adf9944fD67DBb3bb13888f2B,
            registryModuleOwnerCustom: 0x763685240370758c5ac6C5F7c22AB36684c0570E,
            link: 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06,
            confirmations: 2,
            nativeCurrencySymbol: "BNB"
        });
        return bscTestnetConfig;
    }

    function getUnichainSepoliaConfig() public pure returns (NetworkConfig memory) {
    NetworkConfig memory unichainSepoliaConfig = NetworkConfig({
        chainSelector: 0, // Replace with actual chain selector (e.g., from Chainlink CCIP docs)
        router: 0x0000000000000000000000000000000000000000, // Replace with actual router address
        rmnProxy: 0x0000000000000000000000000000000000000000, // Replace with actual RMN proxy address
        tokenAdminRegistry: 0x0000000000000000000000000000000000000000, // Replace with actual token admin registry address
        registryModuleOwnerCustom: 0x0000000000000000000000000000000000000000, // Replace with actual registry module owner custom address
        link: 0x0000000000000000000000000000000000000000, // Replace with actual LINK token address
        confirmations: 2, // Adjust if needed
        nativeCurrencySymbol: "ETH" // Adjust if Unichain Sepolia uses a different symbol
    });
    return unichainSepoliaConfig;
}
}