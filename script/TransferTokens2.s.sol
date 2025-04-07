// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseScript} from "./BaseScript.s.sol";
import "forge-std/console.sol";
import "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import { ERC20, ERC20Burnable, IERC20 } from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract TransferTokens is BaseScript {
    // Hardcode source and destination chains for this example
    string sourceChainName = "ArbitrumSepolia";
    // string sourceChainName = "BSCTestnet";
    string destinationChainName = "BSCTestnet";
    // string destinationChainName = "ArbitrumSepolia";

    function run() external {
        address sender = address(0xAE1710C414E95B83c247E01E8F30eE117771599B);
        address receiver = address(0xAE1710C414E95B83c247E01E8F30eE117771599B); // Destination address on Arbitrum Sepolia
        uint256 amount = 1000; // Amount to transfer (in wei, e.g., 100 * 10^18)

        console.log("Sender:", sender);
        console.log("Receiver:", receiver);
        console.log("Amount:", amount);

        // Find source and destination network details
        uint256 sourceIndex = type(uint256).max;
        uint256 destIndex = type(uint256).max;
        for (uint256 i = 0; i < networks.length; i++) {
            if (keccak256(abi.encodePacked(networks[i].name)) == keccak256(abi.encodePacked(sourceChainName))) {
                sourceIndex = i;
            }
            if (keccak256(abi.encodePacked(networks[i].name)) == keccak256(abi.encodePacked(destinationChainName))) {
                destIndex = i;
            }
        }
        require(sourceIndex != type(uint256).max, "Source chain not found");
        require(destIndex != type(uint256).max, "Destination chain not found");

        NetworkDetails storage sourceNetwork = networks[sourceIndex];
        NetworkDetails storage destNetwork = networks[destIndex];

        // Ensure token and pool addresses are set from previous deployment
        require(sourceNetwork.token != address(0), "Token not deployed on source chain");
        require(sourceNetwork.pool != address(0), "Pool not deployed on source chain");

        console.log("Transferring from", sourceNetwork.name, "to", destNetwork.name);
        console.log("Source Token:", sourceNetwork.token);
        console.log("Source Router:", sourceNetwork.routerAddress);

        vm.startBroadcast(sender);

        // Approve the Router to spend tokens
        IERC20 token = IERC20(sourceNetwork.token);
        token.approve(sourceNetwork.routerAddress, amount);
        console.log("Approved Router to spend", amount, "tokens");


        // Approve LINK for fees (assuming sender has LINK)
        IERC20 link = IERC20(sourceNetwork.linkAddress);
        console.log("source Link Token",sourceNetwork.linkAddress);
        uint256 linkAllowance = link.allowance(sender, sourceNetwork.routerAddress);
        if (linkAllowance < 20 ether) { // Arbitrary LINK amount for fees
            link.approve(sourceNetwork.routerAddress, 20 ether);
            console.log("Approved Router to spend 20 LINK for fees");
        }

        // Construct CCIP message
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: "", // No additional data for simple transfer
            tokenAmounts: new Client.EVMTokenAmount[](1),
            feeToken: sourceNetwork.linkAddress, // Pay with LINK
            extraArgs: abi.encodePacked(
                bytes4(keccak256("CCIP EVMExtraArgsV1")), // Extra arguments for CCIP (versioned)
                abi.encode(uint256(0)) // Placeholder for future use
            )
        });

        message.tokenAmounts[0] = Client.EVMTokenAmount({
            token: sourceNetwork.token,
            amount: amount
        });

        // Send tokens via CCIP
        IRouterClient router = IRouterClient(sourceNetwork.routerAddress);
        bytes32 messageId = router.ccipSend(destNetwork.chainSelector, message);

        vm.stopBroadcast();

        console.log("Transfer initiated! Message ID:", vm.toString(messageId));
        console.log("Track it at: https://ccip.chain.link/msg/", vm.toString(messageId));
    }
}