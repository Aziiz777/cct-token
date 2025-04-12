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
        /////////////////mainnet/////////////////////
        if (block.chainid == 1) {
            activeNetworkConfig = getEthereumMainnetConfig();
        } else if (block.chainid == 42161) {
            activeNetworkConfig = getArbitrumOneConfig();
        } else if (block.chainid == 43114) {
            activeNetworkConfig = getAvalancheCChainConfig();
        } else if (block.chainid == 8453) {
            activeNetworkConfig = getBaseMainnetConfig();
        } else if (block.chainid == 56) {
            activeNetworkConfig = getBNBChainConfig();
        } else if (block.chainid == 10) {
            activeNetworkConfig = getOptimismConfig();
        } else if (block.chainid == 137) {
            activeNetworkConfig = getPolygonConfig();
        } else if (block.chainid == 1088) {
            activeNetworkConfig = getMetisMainnetConfig();
        } else if (block.chainid == 1329) {
            activeNetworkConfig = getSeiMainnetConfig();
        } else if (block.chainid == 42220) {
            activeNetworkConfig = getCeloMainnetConfig();
        } else if (block.chainid == 2020) {
            activeNetworkConfig = getRoninMainnetConfig();
        }

        /////////////testnets//////////////////// 

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
    ///////////////////mainnets/////////////////////////

     function getEthereumMainnetConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethereumMainnetConfig = NetworkConfig({
            chainSelector: 5009297550715157269,
            router: 0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D,
            rmnProxy: 0x411dE17f12D1A34ecC7F45f49844626267c75e81,
            tokenAdminRegistry: 0xb22764f98dD05c789929716D677382Df22C05Cb6,
            registryModuleOwnerCustom: 0x4855174E9479E211337832E109E7721d43A4CA64,
            link: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            confirmations: 3,
            nativeCurrencySymbol: "ETH"
        });
        return ethereumMainnetConfig;
    }

    function getArbitrumOneConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory arbitrumOneConfig = NetworkConfig({
            chainSelector: 4949039107694359620,
            router: 0x141fa059441E0ca23ce184B6A78bafD2A517DdE8,
            rmnProxy: 0xC311a21e6fEf769344EB1515588B9d535662a145,
            tokenAdminRegistry: 0x39AE1032cF4B334a1Ed41cdD0833bdD7c7E7751E,
            registryModuleOwnerCustom: 0x1f1df9f7fc939E71819F766978d8F900B816761b,
            link: 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4,
            confirmations: 3,
            nativeCurrencySymbol: "ETH"
        });
        return arbitrumOneConfig;
    }

    function getAvalancheCChainConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory avalancheCChainConfig = NetworkConfig({
            chainSelector: 6433500567565415381,
            router: 0xF4c7E640EdA248ef95972845a62bdC74237805dB,
            rmnProxy: 0xcBD48A8eB077381c3c4Eb36b402d7283aB2b11Bc,
            tokenAdminRegistry: 0xc8df5D618c6a59Cc6A311E96a39450381001464F,
            registryModuleOwnerCustom: 0x76Aa17dCda9E8529149E76e9ffaE4aD1C4AD701B,
            link: 0x5947BB275c521040051D82396192181b413227A3,
            confirmations: 2,
            nativeCurrencySymbol: "AVAX"
        });
        return avalancheCChainConfig;
    }

    function getBaseMainnetConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory baseMainnetConfig = NetworkConfig({
            chainSelector: 15971525489660198786,
            router: 0x881e3A65B4d4a04dD529061dd0071cf975F58bCD,
            rmnProxy: 0xC842c69d54F83170C42C4d556B4F6B2ca53Dd3E8,
            tokenAdminRegistry: 0x6f6C373d09C07425BaAE72317863d7F6bb731e37,
            registryModuleOwnerCustom: 0xAFEd606Bd2CAb6983fC6F10167c98aaC2173D77f,
            link: 0x88Fb150BDc53A65fe94Dea0c9BA0a6dAf8C6e196,
            confirmations: 3,
            nativeCurrencySymbol: "ETH"
        });
        return baseMainnetConfig;
    }

    function getBNBChainConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory bnbChainConfig = NetworkConfig({
            chainSelector: 11344663589394136015,
            router: 0x34B03Cb9086d7D758AC55af71584F81A598759FE,
            rmnProxy: 0x9e09697842194f77d315E0907F1Bda77922e8f84,
            tokenAdminRegistry: 0x736Fd8660c443547a85e4Eaf70A49C1b7Bb008fc,
            registryModuleOwnerCustom: 0x47Db76c9c97F4bcFd54D8872FDb848Cab696092d,
            link: 0x404460C6A5EdE2D891e8297795264fDe62ADBB75,
            confirmations: 3,
            nativeCurrencySymbol: "BNB"
        });
        return bnbChainConfig;
    }

    function getOptimismConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory optimismConfig = NetworkConfig({
            chainSelector: 3734403246176062136,
            router: 0x3206695CaE29952f4b0c22a169725a865bc8Ce0f,
            rmnProxy: 0x55b3FCa23EdDd28b1f5B4a3C7975f63EFd2d06CE,
            tokenAdminRegistry: 0x657c42abE4CD8aa731Aec322f871B5b90cf6274F,
            registryModuleOwnerCustom: 0xAFEd606Bd2CAb6983fC6F10167c98aaC2173D77f,
            link: 0x350a791Bfc2C21F9Ed5d10980Dad2e2638ffa7f6,
            confirmations: 3,
            nativeCurrencySymbol: "ETH"
        });
        return optimismConfig;
    }

    function getPolygonConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory polygonConfig = NetworkConfig({
            chainSelector: 4051577828743386545,
            router: 0x849c5ED5a80F5B408Dd4969b78c2C8fdf0565Bfe,
            rmnProxy: 0xf1ceAa46D8d13Cac9fC38aaEF3d3d14754C5A9c2,
            tokenAdminRegistry: 0x00F027eA6D0fb03256A15E9182B2B9227A4931d8,
            registryModuleOwnerCustom: 0xc751E86208F0F8aF2d5CD0e29716cA7AD98B5eF5,
            link: 0xb0897686c545045aFc77CF20eC7A532E3120E0F1    ,
            confirmations: 3,
            nativeCurrencySymbol: "MATIC"
        });
        return polygonConfig;
    }

     function getMetisMainnetConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory metisMainnetConfig = NetworkConfig({
            chainSelector: 8805746078405598895,
            router: 0x7b9FB8717D306e2e08ce2e1Efa81F026bf9AD13c,
            rmnProxy: 0xd99cc1d64027E07Cd2AaE871E16bb32b8F401998,
            tokenAdminRegistry: 0x3af897541eB03927c7431bF68884A6C2C23b683f,
            registryModuleOwnerCustom: 0xE4B147224Db9B6E3776E4B3CEda31b3cE232e2FA,
            link: 0xd2FE54D1E5F568eB710ba9d898Bf4bD02C7c0353,
            confirmations: 3,
            nativeCurrencySymbol: "METIS"
        });
        return metisMainnetConfig;
    }

    function getSeiMainnetConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory seiMainnetConfig = NetworkConfig({
            chainSelector: 9027416829622342829,
            router: 0xAba60dA7E88F7E8f5868C2B6dE06CB759d693af0,
            rmnProxy: 0x32C67585dA17839245c75D80d36c8CBD7d35E1a5,
            tokenAdminRegistry: 0x910a46cA93E8086BF1d7D65190eE6AEe5256Bd61, 
            registryModuleOwnerCustom: 0xd7327405609E3f9566830b1aCF79E25AC0a9DA4B,
            link: 0x71052BAe71C25C78E37fD12E5ff1101A71d9018F,
            confirmations: 3,
            nativeCurrencySymbol: "SEI"
        });
        return seiMainnetConfig;
    }

    function getCeloMainnetConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory celoMainnetConfig = NetworkConfig({
            chainSelector: 1346049177634351622,
            router: 0xfB48f15480926A4ADf9116Dca468bDd2EE6C5F62,
            rmnProxy: 0x56e0507d4E69D98bE7Eb4ada01d2315596F9f281,
            tokenAdminRegistry: 0xf19e0555fAA9051e277eeD5A0DcdB13CDaca39a9,
            registryModuleOwnerCustom: 0xb0112a2723D9D6CB5194580701A93B1eb67846D2,
            link: 0xd07294e6E917e07dfDcee882dd1e2565085C2ae0,
            confirmations: 3,
            nativeCurrencySymbol: "CELO"
        });
        return celoMainnetConfig;
    }

    function getRoninMainnetConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory roninMainnetConfig = NetworkConfig({
            chainSelector: 6916147374840168594,
            router: 0x46527571D5D1B68eE7Eb60B18A32e6C60DcEAf99,
            rmnProxy: 0xceA253a8c2BB995054524d071498281E89aACD59,
            tokenAdminRegistry: 0x90e83d532A4aD13940139c8ACE0B93b0DdbD323a,
            registryModuleOwnerCustom: 0x5055DA89A16b71fEF91D1af323b139ceDe2d8320,
            link: 0x3902228D6A3d2Dc44731fD9d45FeE6a61c722D0b,
            confirmations: 3,
            nativeCurrencySymbol: "RON"
        });
        return roninMainnetConfig;
    }

    ///////////////////testnets/////////////////////////
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