// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseScript} from "./BaseScript.s.sol";
import "forge-std/console.sol";

contract DeployAndConfigure is BaseScript {
    function run() external {
        address deployer = address(0xAE1710C414E95B83c247E01E8F30eE117771599B);

        // Deploy to all networks
        for (uint256 i = 0; i < networks.length; i++) {
            console.log("Deploying to", networks[i].name);
            vm.startBroadcast(deployer);

            networks[i].token = address(deployToken());
            networks[i].pool = address(deployPool(
                networks[i].token,
                networks[i].rmnProxyAddress,
                networks[i].routerAddress
            ));
            grantRoles(networks[i].token, networks[i].pool);
            setupAdminAndPool(
                networks[i].token,
                networks[i].pool,
                networks[i].tokenAdminRegistryAddress,
                networks[i].registryModuleOwnerCustomAddress
            );

            vm.stopBroadcast();
        }

        // Configure pools with remote chain details
        for (uint256 i = 0; i < networks.length; i++) {
            console.log("Configuring pool on", networks[i].name);
            vm.startBroadcast(deployer);

            uint64[] memory remoteChainSelectors = new uint64[](networks.length - 1);
            address[] memory remotePools = new address[](networks.length - 1);
            address[] memory remoteTokens = new address[](networks.length - 1);
            uint256 index = 0;
            for (uint256 j = 0; j < networks.length; j++) {
                if (j != i) {
                    remoteChainSelectors[index] = networks[j].chainSelector;
                    remotePools[index] = networks[j].pool;
                    remoteTokens[index] = networks[j].token;
                    index++;
                }
            }
            configurePool(networks[i].pool, remoteChainSelectors, remotePools, remoteTokens);

            vm.stopBroadcast();
        }

        console.log("Deployment and Configuration Complete!");
    }
}