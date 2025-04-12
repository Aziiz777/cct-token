// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/MiddleEastE-commerce.sol";
import "@pancakeswap-v2-core/interfaces/IPancakeFactory.sol";
import "@pancakeswap-v2-periphery/interfaces/IPancakeRouter02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CreatePancakeSwapV2PairAndAddLiquidity is Script {
    // PancakeSwap V2 Factory and Router addresses
    address public constant MAINNET_FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address public constant MAINNET_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public constant TESTNET_FACTORY = 0x6725F303b657a9451d8BA641348b6761A6CC7a17;
    address public constant TESTNET_ROUTER = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;

    // Common paired tokens (for reference)
    address public constant MAINNET_WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant MAINNET_BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant TESTNET_WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address public constant TESTNET_BUSD = 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47;

    function run() public {
        // Fetch arguments from environment variables
        address phoneToken = vm.envAddress("PHONE_TOKEN");
        address pairedToken = vm.envAddress("PAIRED_TOKEN");
        bool isMainnet = vm.envBool("IS_MAINNET");
        bool addLiquidity = vm.envBool("ADD_LIQUIDITY");
        uint256 amountPhone = vm.envUint("AMOUNT_PHONE");
        uint256 amountPaired = vm.envUint("AMOUNT_PAIRED");
        uint256 deadlineOffset = vm.envUint("DEADLINE_OFFSET");
        // address deployer = vm.envAddress("DEPLOYER_ADDRESS");

        vm.startBroadcast();

        // Select Factory and Router based on network
        address factory = isMainnet ? MAINNET_FACTORY : TESTNET_FACTORY;
        address router = isMainnet ? MAINNET_ROUTER : TESTNET_ROUTER;

        // Check if pair exists, create it if not
        address pair = IPancakeFactory(factory).getPair(phoneToken, pairedToken);
        if (pair == address(0)) {
            pair = IPancakeFactory(factory).createPair(phoneToken, pairedToken);
            console.log("New PancakeSwap V2 pair created at:", pair);
        } else {
            console.log("Pair already exists at:", pair);
        }

        // Add liquidity if requested
        if (addLiquidity) {
            IERC20(phoneToken).approve(router, amountPhone);
            IERC20(pairedToken).approve(router, amountPaired);

            if (pairedToken == (isMainnet ? MAINNET_WBNB : TESTNET_WBNB)) {
                // Handle WBNB (native BNB) liquidity
                IPancakeRouter02(router).addLiquidityETH{value: amountPaired}(
                    phoneToken,
                    amountPhone,
                    0, // Minimum amount of phoneToken
                    0, // Minimum amount of BNB
                    msg.sender, // Recipient of LP tokens
                    block.timestamp + deadlineOffset
                );
                console.log("Liquidity added to phoneToken-WBNB pair with %s PH and %s BNB", amountPhone, amountPaired);
            } else {
                // Handle ERC20 paired tokens (e.g., BUSD)
                IPancakeRouter02(router).addLiquidity(
                    phoneToken,
                    pairedToken,
                    amountPhone,
                    amountPaired,
                    0, // Minimum amount of phoneToken
                    0, // Minimum amount of pairedToken
                    msg.sender, // Recipient of LP tokens
                    block.timestamp + deadlineOffset
                );
                console.log("Liquidity added to phoneToken-%s pair with %s PH and %s paired token", pairedToken, amountPhone, amountPaired);
            }
        }

        vm.stopBroadcast();
    }
}