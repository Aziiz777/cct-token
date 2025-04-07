// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import { IBurnMintERC20 } from "@chainlink-ccip/contracts-ccip/src/v0.8/shared/token/ERC20/IBurnMintERC20.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {phoneToken} from "../src/phone.sol";
import {BurnMintTokenPool} from "@chainlink-ccip/contracts-ccip/src/v0.8/ccip/pools/BurnMintTokenPool.sol";
import {TokenPool} from "@chainlink-ccip/contracts-ccip/src/v0.8/ccip/pools/TokenPool.sol";
import {IRouter} from "@chainlink-ccip/contracts-ccip/src/v0.8/ccip/interfaces/IRouter.sol";
import {TokenAdminRegistry} from "@chainlink-ccip/contracts-ccip/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {RegistryModuleOwnerCustom} from "@chainlink-ccip/contracts-ccip/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {RateLimiter} from "@chainlink-ccip/contracts-ccip/src/v0.8/ccip/libraries/RateLimiter.sol";

contract BaseScript is Script {
    address owner = address(0xAE1710C414E95B83c247E01E8F30eE117771599B);
    struct NetworkDetails {
        string name;
        uint256 chainId;
        uint64 chainSelector;
        address routerAddress;
        address linkAddress;
        address rmnProxyAddress;
        address tokenAdminRegistryAddress;
        address registryModuleOwnerCustomAddress;
        address token;
        address pool;
    }

    NetworkDetails[] public networks;
    HelperConfig public helperConfig;

    function setUp() public virtual {
        helperConfig = new HelperConfig();
        
        networks.push(NetworkDetails({
            name: "EthereumSepolia",
            chainId: 11155111,
            chainSelector: helperConfig.getEthereumSepoliaConfig().chainSelector,
            routerAddress: helperConfig.getEthereumSepoliaConfig().router,
            linkAddress: helperConfig.getEthereumSepoliaConfig().link,
            rmnProxyAddress: helperConfig.getEthereumSepoliaConfig().rmnProxy,
            tokenAdminRegistryAddress: helperConfig.getEthereumSepoliaConfig().tokenAdminRegistry,
            registryModuleOwnerCustomAddress: helperConfig.getEthereumSepoliaConfig().registryModuleOwnerCustom,
            token: 0xb8A39E17c49777407AB9dB7e663BB02324e5C642,
            pool: 0x7F82767cb665661c3040Ec19CC0A963482D969F6
        }));

        networks.push(NetworkDetails({
            name: "ArbitrumSepolia",
            chainId: 421614,
            chainSelector: helperConfig.getArbitrumSepolia().chainSelector,
            routerAddress: helperConfig.getArbitrumSepolia().router,
            linkAddress: helperConfig.getArbitrumSepolia().link,
            rmnProxyAddress: helperConfig.getArbitrumSepolia().rmnProxy,
            tokenAdminRegistryAddress: helperConfig.getArbitrumSepolia().tokenAdminRegistry,
            registryModuleOwnerCustomAddress: helperConfig.getArbitrumSepolia().registryModuleOwnerCustom,
            token: 0x27284f231245df71D174Eb143c89dCD79B98a920,
            pool: 0xd14e942eD5Faa4a760f70D1AB43eCb836c827012
        }));
        networks.push(NetworkDetails({
            name: "BSCTestnet",
            chainId: 97,
            chainSelector: helperConfig.getBSCTestnetConfig().chainSelector,
            routerAddress: helperConfig.getBSCTestnetConfig().router,
            linkAddress: helperConfig.getBSCTestnetConfig().link,
            rmnProxyAddress: helperConfig.getBSCTestnetConfig().rmnProxy,
            tokenAdminRegistryAddress: helperConfig.getBSCTestnetConfig().tokenAdminRegistry,
            registryModuleOwnerCustomAddress: helperConfig.getBSCTestnetConfig().registryModuleOwnerCustom,
            token: 0x2a16a94262Cb2243266A13Af07C4f69bf5087786,
            pool:  0xF628798084146cA57D9cE0F298d1B73Cb2334744
        }));

    //     networks.push(NetworkDetails({
    //     name: "UnichainSepolia",
    //     chainId: 1301,
    //     chainSelector: helperConfig.getUnichainSepoliaConfig().chainSelector,
    //     routerAddress: helperConfig.getUnichainSepoliaConfig().router,
    //     linkAddress: helperConfig.getUnichainSepoliaConfig().link,
    //     rmnProxyAddress: helperConfig.getUnichainSepoliaConfig().rmnProxy,
    //     tokenAdminRegistryAddress: helperConfig.getUnichainSepoliaConfig().tokenAdminRegistry,
    //     registryModuleOwnerCustomAddress: helperConfig.getUnichainSepoliaConfig().registryModuleOwnerCustom,
    //     token: 0x0000000000000000000000000000000000000000, // Replace with actual token address
    //     pool: 0x0000000000000000000000000000000000000000  // Replace with actual pool address
    // }));
        
    }

    function deployToken() internal returns (phoneToken) {
        phoneToken token = new phoneToken(address(owner));
        console.log("Deployed Token:", address(token));
        grantRoles(address(token),msg.sender);
        phoneToken(token).addToWhitelist(address(msg.sender));
        return token;
    }

    function deployPool(address token, address rmnProxy, address router) internal returns (BurnMintTokenPool) {
        address[] memory allowlist = new address[](0);
        BurnMintTokenPool pool = new BurnMintTokenPool(
            IBurnMintERC20(token),
            18,
            allowlist,
            rmnProxy,
            router
        );
        phoneToken(token).addToWhitelist(address(pool));
        console.log("Deployed Pool:", address(pool));
        return pool;
    }

    function grantRoles(address token, address pool) internal {
        phoneToken(token).grantRole(
            phoneToken(token).MINTER_ROLE(),
            pool
        );
        phoneToken(token).grantRole(
            phoneToken(token).BURNER_ROLE(),
            pool
        );
        console.log("Roles Granted to Pool:", pool);
    }

    function setupAdminAndPool(
        address token,
        address pool,
        address tokenAdminRegistry,
        address registryModuleOwnerCustom
    ) internal {
        RegistryModuleOwnerCustom(registryModuleOwnerCustom).registerAdminViaGetCCIPAdmin(token);
        TokenAdminRegistry(tokenAdminRegistry).acceptAdminRole(token);
        TokenAdminRegistry(tokenAdminRegistry).setPool(token, pool);
        console.log("Admin and Pool Configured for Token:", token);
    }
// Check if a chain is configured in the pool
    function isChainConfigured(address pool, uint64 chainSelector) internal view returns (bool) {
        uint64[] memory supportedChains = TokenPool(pool).getSupportedChains();
        for (uint256 i = 0; i < supportedChains.length; i++) {
            if (supportedChains[i] == chainSelector) {
                return true;
            }
        }
        return false;
    }

    // Debug function to log supported chains
    function logSupportedChains(address pool) internal view {
        uint64[] memory supportedChains = TokenPool(pool).getSupportedChains();
        console.log("Supported chains for pool: %s", pool);
        for (uint256 i = 0; i < supportedChains.length; i++) {
            console.log(" - Chain Selector: %s", supportedChains[i]);
        }
    }

    // Get remote chain details, including all non-current chains not yet configured
    function getRemoteChainDetails(uint256 currentChainId, address pool)
        internal
        view
        returns (
            uint64[] memory remoteChainSelectors,
            address[] memory remotePools,
            address[] memory remoteTokens
        )
    {
        uint256 remoteCount = 0;
        for (uint256 i = 0; i < networks.length; i++) {
            if (networks[i].chainId != currentChainId && !isChainConfigured(pool, networks[i].chainSelector)) {
                console.log("Found unconfigured chain: %s Selector: %s", networks[i].name, networks[i].chainSelector);
                remoteCount++;
            }
        }

        remoteChainSelectors = new uint64[](remoteCount);
        remotePools = new address[](remoteCount);
        remoteTokens = new address[](remoteCount);

        uint256 index = 0;
        for (uint256 i = 0; i < networks.length; i++) {
            if (networks[i].chainId != currentChainId && !isChainConfigured(pool, networks[i].chainSelector)) {
                remoteChainSelectors[index] = networks[i].chainSelector;
                remotePools[index] = networks[i].pool;
                remoteTokens[index] = networks[i].token;
                console.log("Adding chain: %s Pool: %s Token: %s", networks[i].name, networks[i].pool, networks[i].token);
                index++;
            }
        }
    }
    function logRouterSupportedChains(address router) internal view {
        address onRampEth = IRouter(router).getOnRamp(16015286601757825753); // Ethereum Sepolia
        address onRampArb = IRouter(router).getOnRamp(3478487238524512106);  // Arbitrum Sepolia
        address onRampBsc = IRouter(router).getOnRamp(13264668187771770619); // BSC Testnet
        console.log("Router %s OnRamps:", router);
        console.log(" - Ethereum Sepolia: %s", onRampEth);
        console.log(" - Arbitrum Sepolia: %s", onRampArb);
        console.log(" - BSC Testnet: %s", onRampBsc);
    }
    function configurePool(
        address pool,
        uint64[] memory remoteChainSelectors,
        address[] memory remotePools,
        address[] memory remoteTokens
    ) internal {
        logSupportedChains(pool);
        logRouterSupportedChains(TokenPool(pool).getRouter()); // Add this line

        if (remoteChainSelectors.length == 0) {
            console.log("No new chains to configure for pool: %s", pool);
        }

        TokenPool.ChainUpdate[] memory chains = new TokenPool.ChainUpdate[](remoteChainSelectors.length);
        for (uint256 i = 0; i < remoteChainSelectors.length; i++) {
            bytes[] memory remotePoolAddresses = new bytes[](1);
            remotePoolAddresses[0] = abi.encode(remotePools[i]);
            chains[i] = TokenPool.ChainUpdate({
                remoteChainSelector: remoteChainSelectors[i],
                remotePoolAddresses: remotePoolAddresses,
                remoteTokenAddress: abi.encode(remoteTokens[i]),
                outboundRateLimiterConfig: RateLimiter.Config({ isEnabled: false, capacity: 0, rate: 0 }),
                inboundRateLimiterConfig: RateLimiter.Config({ isEnabled: false, capacity: 0, rate: 0 })
            });
        }

        try BurnMintTokenPool(pool).applyChainUpdates(new uint64[](0), chains) {
            console.log("Pool Configured with %s new remote chains", remoteChainSelectors.length);
        } catch Error(string memory reason) {
            console.log("Failed to configure pool: %s Reason: %s", pool, reason);
        }
    }
}