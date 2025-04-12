// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseScript} from "./BaseScript.s.sol";
import "forge-std/console.sol";

contract Deploy is BaseScript {
    function run() external {
        address deployer = address(0xbf50Be5CE4d697AC06DE50eFb7D545E892575635);

        uint256 currentChainId = block.chainid;
        console.log("Deploying on Chain ID:", currentChainId);

        uint256 networkIndex = type(uint256).max;
        for (uint256 i = 0; i < networks.length; i++) {
            if (networks[i].chainId == currentChainId) {
                networkIndex = i;
                break;
            }
        }
        require(networkIndex != type(uint256).max, "Chain ID not supported");

        NetworkDetails storage network = networks[networkIndex];
        console.log("Deploying to", network.name);

        vm.startBroadcast(deployer);

        network.token = address(deployToken());
        network.pool = address(deployPool(
            network.token,
            network.rmnProxyAddress,
            network.routerAddress
        ));
        grantRoles(network.token, network.pool);
        setupAdminAndPool(
            network.token,
            network.pool,
            network.tokenAdminRegistryAddress,
            network.registryModuleOwnerCustomAddress
        );

        vm.stopBroadcast();

        console.log("Deployment Complete on", network.name);
        console.log("Token Address:", network.token);
        console.log("Pool Address:", network.pool);
    }
}