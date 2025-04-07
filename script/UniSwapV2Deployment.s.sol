// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "@uniswap/v2-core/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CreateUniswapV2PairAndAddLiquidity is Script {
    // Uniswap V2 Factory and Router addresses
    address public constant MAINNET_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant MAINNET_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant SEPOLIA_FACTORY = 0x7E0987E5b3a30e3f2828572Bb659A548460a3003;
    address public constant SEPOLIA_ROUTER = 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008;

    function run() public {
        // Fetch arguments from environment variables
        address phoneToken = vm.envAddress("PHONE_TOKEN");
        address pairedToken = vm.envAddress("PAIRED_TOKEN");
        bool isMainnet = vm.envBool("IS_MAINNET");
        bool addLiquidity = vm.envBool("ADD_LIQUIDITY");
        uint256 amountPhone = vm.envUint("AMOUNT_PHONE");
        uint256 amountPaired = vm.envUint("AMOUNT_PAIRED");
        uint256 deadlineOffset = vm.envUint("DEADLINE_OFFSET");

        vm.startBroadcast();

        // Select Factory and Router based on network
        address factory = isMainnet ? MAINNET_FACTORY : SEPOLIA_FACTORY;
        address router = isMainnet ? MAINNET_ROUTER : SEPOLIA_ROUTER;

        // Check if pair exists, create it if not
        address pair = IUniswapV2Factory(factory).getPair(phoneToken, pairedToken);
        if (pair == address(0)) {
            pair = IUniswapV2Factory(factory).createPair(phoneToken, pairedToken);
            console.log("New Uniswap V2 pair created at:", pair);
        } else {
            console.log("Pair already exists at:", pair);
        }

        // Add liquidity if requested
        if (addLiquidity) {
            IERC20(phoneToken).approve(router, amountPhone);
            IERC20(pairedToken).approve(router, amountPaired);

            IUniswapV2Router02(router).addLiquidity(
                phoneToken,
                pairedToken,
                amountPhone,
                amountPaired,
                0, // Minimum amount of phoneToken
                0, // Minimum amount of pairedToken
                msg.sender, // Recipient of LP tokens
                block.timestamp + deadlineOffset // Configurable deadline
            );
            console.log("Liquidity added to the pair.");
        }

        vm.stopBroadcast();
    }
}