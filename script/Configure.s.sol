// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseScript} from "./BaseScript.s.sol";
import "forge-std/console.sol";

contract Configure is BaseScript {
    function run() external {
        address deployer = address(0xAE1710C414E95B83c247E01E8F30eE117771599B);

        uint256 currentChainId = block.chainid;
        console.log("Configuring on Chain ID:", currentChainId);

        uint256 networkIndex = type(uint256).max;
        for (uint256 i = 0; i < networks.length; i++) {
            if (networks[i].chainId == currentChainId) {
                networkIndex = i;
                break;
            }
        }
        require(networkIndex != type(uint256).max, "Chain ID not supported");

        NetworkDetails storage network = networks[networkIndex];
        console.log("Configuring on", network.name);

        vm.startBroadcast(deployer);

        (uint64[] memory remoteChainSelectors, address[] memory remotePools, address[] memory remoteTokens) =
            getRemoteChainDetails(currentChainId, network.pool);
        configurePool(network.pool, remoteChainSelectors, remotePools, remoteTokens);

        vm.stopBroadcast();

        console.log("Configuration Complete on", network.name);
        console.log("Pool Address:", network.pool);
    }
}