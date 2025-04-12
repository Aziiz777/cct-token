// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import { IBurnMintERC20 } from "@chainlink-ccip/contracts-ccip/src/v0.8/shared/token/ERC20/IBurnMintERC20.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {MiddleEastECommerce} from "../src/MiddleEastE-commerce.sol";
import {BurnMintTokenPool} from "@chainlink-ccip/contracts-ccip/src/v0.8/ccip/pools/BurnMintTokenPool.sol";
import {TokenPool} from "@chainlink-ccip/contracts-ccip/src/v0.8/ccip/pools/TokenPool.sol";
import {IRouter} from "@chainlink-ccip/contracts-ccip/src/v0.8/ccip/interfaces/IRouter.sol";
import {TokenAdminRegistry} from "@chainlink-ccip/contracts-ccip/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {RegistryModuleOwnerCustom} from "@chainlink-ccip/contracts-ccip/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {RateLimiter} from "@chainlink-ccip/contracts-ccip/src/v0.8/ccip/libraries/RateLimiter.sol";

contract BaseScript is Script {
    address owner = address(0xbf50Be5CE4d697AC06DE50eFb7D545E892575635);
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
        
        Mainnet Configurations
        networks.push(NetworkDetails({
            name: "EthereumMainnet",
            chainId: 1,
            chainSelector: helperConfig.getEthereumMainnetConfig().chainSelector,
            routerAddress: helperConfig.getEthereumMainnetConfig().router,
            linkAddress: helperConfig.getEthereumMainnetConfig().link,
            rmnProxyAddress: helperConfig.getEthereumMainnetConfig().rmnProxy,
            tokenAdminRegistryAddress: helperConfig.getEthereumMainnetConfig().tokenAdminRegistry,
            registryModuleOwnerCustomAddress: helperConfig.getEthereumMainnetConfig().registryModuleOwnerCustom,
            token: 0x0000000000000000000000000000000000000000,
            pool: 0x0000000000000000000000000000000000000000
        }));

        networks.push(NetworkDetails({
            name: "ArbitrumOne",
            chainId: 42161,
            chainSelector: helperConfig.getArbitrumOneConfig().chainSelector,
            routerAddress: helperConfig.getArbitrumOneConfig().router,
            linkAddress: helperConfig.getArbitrumOneConfig().link,
            rmnProxyAddress: helperConfig.getArbitrumOneConfig().rmnProxy,
            tokenAdminRegistryAddress: helperConfig.getArbitrumOneConfig().tokenAdminRegistry,
            registryModuleOwnerCustomAddress: helperConfig.getArbitrumOneConfig().registryModuleOwnerCustom,
            token: 0x0000000000000000000000000000000000000000,
            pool: 0x0000000000000000000000000000000000000000
        }));

        networks.push(NetworkDetails({
            name: "AvalancheCChain",
            chainId: 43114,
            chainSelector: helperConfig.getAvalancheCChainConfig().chainSelector,
            routerAddress: helperConfig.getAvalancheCChainConfig().router,
            linkAddress: helperConfig.getAvalancheCChainConfig().link,
            rmnProxyAddress: helperConfig.getAvalancheCChainConfig().rmnProxy,
            tokenAdminRegistryAddress: helperConfig.getAvalancheCChainConfig().tokenAdminRegistry,
            registryModuleOwnerCustomAddress: helperConfig.getAvalancheCChainConfig().registryModuleOwnerCustom,
            token: 0x0000000000000000000000000000000000000000,
            pool: 0x0000000000000000000000000000000000000000
        }));

        networks.push(NetworkDetails({
            name: "BaseMainnet",
            chainId: 8453,
            chainSelector: helperConfig.getBaseMainnetConfig().chainSelector,
            routerAddress: helperConfig.getBaseMainnetConfig().router,
            linkAddress: helperConfig.getBaseMainnetConfig().link,
            rmnProxyAddress: helperConfig.getBaseMainnetConfig().rmnProxy,
            tokenAdminRegistryAddress: helperConfig.getBaseMainnetConfig().tokenAdminRegistry,
            registryModuleOwnerCustomAddress: helperConfig.getBaseMainnetConfig().registryModuleOwnerCustom,
            token: 0x0000000000000000000000000000000000000000, 
            pool: 0x0000000000000000000000000000000000000000
        }));

        networks.push(NetworkDetails({
            name: "BNBChain",
            chainId: 56,
            chainSelector: helperConfig.getBNBChainConfig().chainSelector,
            routerAddress: helperConfig.getBNBChainConfig().router,
            linkAddress: helperConfig.getBNBChainConfig().link,
            rmnProxyAddress: helperConfig.getBNBChainConfig().rmnProxy,
            tokenAdminRegistryAddress: helperConfig.getBNBChainConfig().tokenAdminRegistry,
            registryModuleOwnerCustomAddress: helperConfig.getBNBChainConfig().registryModuleOwnerCustom,
            token: 0x0000000000000000000000000000000000000000,
            pool: 0x0000000000000000000000000000000000000000
        }));

        networks.push(NetworkDetails({
            name: "Optimism",
            chainId: 10,
            chainSelector: helperConfig.getOptimismConfig().chainSelector,
            routerAddress: helperConfig.getOptimismConfig().router,
            linkAddress: helperConfig.getOptimismConfig().link,
            rmnProxyAddress: helperConfig.getOptimismConfig().rmnProxy,
            tokenAdminRegistryAddress: helperConfig.getOptimismConfig().tokenAdminRegistry,
            registryModuleOwnerCustomAddress: helperConfig.getOptimismConfig().registryModuleOwnerCustom,
            token: 0x0000000000000000000000000000000000000000,
            pool: 0x0000000000000000000000000000000000000000
        }));

        networks.push(NetworkDetails({
            name: "Polygon",
            chainId: 137,
            chainSelector: helperConfig.getPolygonConfig().chainSelector,
            routerAddress: helperConfig.getPolygonConfig().router,
            linkAddress: helperConfig.getPolygonConfig().link,
            rmnProxyAddress: helperConfig.getPolygonConfig().rmnProxy,
            tokenAdminRegistryAddress: helperConfig.getPolygonConfig().tokenAdminRegistry,
            registryModuleOwnerCustomAddress: helperConfig.getPolygonConfig().registryModuleOwnerCustom,
            token: 0x0000000000000000000000000000000000000000,
            pool: 0x0000000000000000000000000000000000000000
        }));

        networks.push(NetworkDetails({
            name: "MetisMainnet",
            chainId: 1088,
            chainSelector: helperConfig.getMetisMainnetConfig().chainSelector,
            routerAddress: helperConfig.getMetisMainnetConfig().router,
            linkAddress: helperConfig.getMetisMainnetConfig().link,
            rmnProxyAddress: helperConfig.getMetisMainnetConfig().rmnProxy,
            tokenAdminRegistryAddress: helperConfig.getMetisMainnetConfig().tokenAdminRegistry,
            registryModuleOwnerCustomAddress: helperConfig.getMetisMainnetConfig().registryModuleOwnerCustom,
            token: 0x0000000000000000000000000000000000000000,
            pool: 0x0000000000000000000000000000000000000000
        }));

        networks.push(NetworkDetails({
            name: "SeiMainnet",
            chainId: 1329,
            chainSelector: helperConfig.getSeiMainnetConfig().chainSelector,
            routerAddress: helperConfig.getSeiMainnetConfig().router,
            linkAddress: helperConfig.getSeiMainnetConfig().link,
            rmnProxyAddress: helperConfig.getSeiMainnetConfig().rmnProxy,
            tokenAdminRegistryAddress: helperConfig.getSeiMainnetConfig().tokenAdminRegistry,
            registryModuleOwnerCustomAddress: helperConfig.getSeiMainnetConfig().registryModuleOwnerCustom,
            token: 0x0000000000000000000000000000000000000000,
            pool: 0x0000000000000000000000000000000000000000
        }));

        networks.push(NetworkDetails({
            name: "CeloMainnet",
            chainId: 42220,
            chainSelector: helperConfig.getCeloMainnetConfig().chainSelector,
            routerAddress: helperConfig.getCeloMainnetConfig().router,
            linkAddress: helperConfig.getCeloMainnetConfig().link,
            rmnProxyAddress: helperConfig.getCeloMainnetConfig().rmnProxy,
            tokenAdminRegistryAddress: helperConfig.getCeloMainnetConfig().tokenAdminRegistry,
            registryModuleOwnerCustomAddress: helperConfig.getCeloMainnetConfig().registryModuleOwnerCustom,
            token: 0x0000000000000000000000000000000000000000,
            pool: 0x0000000000000000000000000000000000000000
        }));

        networks.push(NetworkDetails({
            name: "RoninMainnet",
            chainId: 2020,
            chainSelector: helperConfig.getRoninMainnetConfig().chainSelector,
            routerAddress: helperConfig.getRoninMainnetConfig().router,
            linkAddress: helperConfig.getRoninMainnetConfig().link,
            rmnProxyAddress: helperConfig.getRoninMainnetConfig().rmnProxy,
            tokenAdminRegistryAddress: helperConfig.getRoninMainnetConfig().tokenAdminRegistry,
            registryModuleOwnerCustomAddress: helperConfig.getRoninMainnetConfig().registryModuleOwnerCustom,
            token: 0x0000000000000000000000000000000000000000,
            pool: 0x0000000000000000000000000000000000000000
        }));


        //testnets configurations ///

        // networks.push(NetworkDetails({
        //     name: "EthereumSepolia",
        //     chainId: 11155111,
        //     chainSelector: helperConfig.getEthereumSepoliaConfig().chainSelector,
        //     routerAddress: helperConfig.getEthereumSepoliaConfig().router,
        //     linkAddress: helperConfig.getEthereumSepoliaConfig().link,
        //     rmnProxyAddress: helperConfig.getEthereumSepoliaConfig().rmnProxy,
        //     tokenAdminRegistryAddress: helperConfig.getEthereumSepoliaConfig().tokenAdminRegistry,
        //     registryModuleOwnerCustomAddress: helperConfig.getEthereumSepoliaConfig().registryModuleOwnerCustom,
        //     token: 0x44bbe76BA377526ff6F5FA3e2F06455a7EA2F4a0,
        //     pool: 0xC459b032cFaD9988e0eF174f7872A2D68f6879BE
        // }));

        // networks.push(NetworkDetails({
        //     name: "ArbitrumSepolia",
        //     chainId: 421614,
        //     chainSelector: helperConfig.getArbitrumSepolia().chainSelector,
        //     routerAddress: helperConfig.getArbitrumSepolia().router,
        //     linkAddress: helperConfig.getArbitrumSepolia().link,
        //     rmnProxyAddress: helperConfig.getArbitrumSepolia().rmnProxy,
        //     tokenAdminRegistryAddress: helperConfig.getArbitrumSepolia().tokenAdminRegistry,
        //     registryModuleOwnerCustomAddress: helperConfig.getArbitrumSepolia().registryModuleOwnerCustom,
        //     token: 0x00A65eFa887A2E6b822DD613d8272788F3b40f5d,
        //     pool: 0x5b27E1BE18523Fcf28B2Dfdc73CbCa267FAF5859
        // }));
        // networks.push(NetworkDetails({
        //     name: "BSCTestnet",
        //     chainId: 97,
        //     chainSelector: helperConfig.getBSCTestnetConfig().chainSelector,
        //     routerAddress: helperConfig.getBSCTestnetConfig().router,
        //     linkAddress: helperConfig.getBSCTestnetConfig().link,
        //     rmnProxyAddress: helperConfig.getBSCTestnetConfig().rmnProxy,
        //     tokenAdminRegistryAddress: helperConfig.getBSCTestnetConfig().tokenAdminRegistry,
        //     registryModuleOwnerCustomAddress: helperConfig.getBSCTestnetConfig().registryModuleOwnerCustom,
        //     token: 0x5436FDbE11CCA6c70f80c1f160e636859b4D7493,
        //     pool:  0x5adad530492e7B0228B31e4935Fb6c3227A46412
        // }));

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

    function deployToken() internal returns (MiddleEastECommerce) {
        MiddleEastECommerce token = new MiddleEastECommerce(address(owner));
        console.log("Deployed Token:", address(token));
        grantRoles(address(token),msg.sender);
        token.addToWhitelist(msg.sender);
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
        MiddleEastECommerce(token).addToWhitelist(address(pool));
        MiddleEastECommerce(token).setTokenPool(address(pool));
        console.log("Deployed Pool:", address(pool));
        return pool;
    }

    function grantRoles(address token, address pool) internal {
        MiddleEastECommerce(token).grantRole(
            MiddleEastECommerce(token).MINTER_ROLE(),
            pool
        );
        MiddleEastECommerce(token).grantRole(
            MiddleEastECommerce(token).BURNER_ROLE(),
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