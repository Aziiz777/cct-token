// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.24;

// import "forge-std/Test.sol";
// import "forge-std/console.sol";
// import "../src/MiddleEastE-commerce.sol"; // Your phoneToken contract
// import "@pancakeswap-v2-core/interfaces/IPancakeFactory.sol";
// import "@pancakeswap-v2-core/interfaces/IPancakePair.sol";
// import "@pancakeswap-v2-periphery/interfaces/IPancakeRouter02.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract PhoneTokenPancakeSwapV2Test is Test {
//     // PancakeSwap V2 mainnet addresses (BSC)
//     address public constant FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
//     address public constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
//     address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
//     address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

//     MiddleEastECommerce public phone;
//     IERC20 public busd = IERC20(BUSD);
//     address public testAddress;

//     // Allow contract to receive BNB
//     receive() external payable {}

//     function setUp() public {
//         // Fork BSC mainnet
//         string memory rpcUrl = vm.envString("BSC_MAINNET_RPC_URL");
//         vm.createFork(rpcUrl);

//         // Deploy phoneToken with testAddress as admin
//         testAddress = address(this);
//         phone = new MiddleEastECommerce(testAddress);

//         // Grant MINTER_ROLE and BURNER_ROLE to test contract (for testing)
//         phone.grantRole(phone.MINTER_ROLE(), testAddress);
//         phone.grantRole(phone.BURNER_ROLE(), testAddress);

//         // Deal BUSD and BNB to test address
//         vm.deal(testAddress, 100 ether); // For WBNB pair
//         deal(BUSD, testAddress, 1000 * 10**18); // 1000 BUSD (18 decimals)
//     }

//     // Helper: Calculate price of phoneToken in terms of other token (e.g., BUSD or WBNB)
//     function getPrice(address pair, address token0, address token1) internal view returns (uint256) {
//         (uint reserve0, uint reserve1,) = IPancakePair(pair).getReserves();
//         if (token0 == address(phone)) {
//             return (reserve1 * 10**18) / reserve0; // Price in token1 (BUSD or WBNB) per PH, normalized to 18 decimals
//         } else {
//             return (reserve0 * 10**18) / reserve1; // Price in token0 per PH
//         }
//     }

//     // Helper: phoneToken-BUSD pair setup
//     function setupPhoneBUSDPair() internal returns (address) {
//         address pair = IPancakeFactory(FACTORY).createPair(address(phone), BUSD);
//         phone.addToWhitelist(pair); // Whitelist pair to bypass restrictions

//         phone.approve(ROUTER, 100 ether); // 100 PH
//         busd.approve(ROUTER, 100 * 10**18); // 100 BUSD

//         IPancakeRouter02(ROUTER).addLiquidity(
//             address(phone),
//             BUSD,
//             100 ether,
//             100 * 10**18,
//             0,
//             0,
//             testAddress,
//             block.timestamp + 1000
//         );
//         return pair;
//     }

//     // Helper: phoneToken-WBNB pair setup
//     function setupPhoneWBNBPair() internal returns (address) {
//         address pair = IPancakeFactory(FACTORY).createPair(address(phone), WBNB);
//         phone.addToWhitelist(pair); // Whitelist pair to bypass restrictions

//         phone.approve(ROUTER, 100 ether);
//         IPancakeRouter02(ROUTER).addLiquidityETH{value: 1 ether}(
//             address(phone),
//             100 ether,
//             0,
//             0,
//             testAddress,
//             block.timestamp + 1000
//         );
//         return pair;
//     }

//     // phoneToken-BUSD Pair Tests

//     function testCreatePairPhoneWithBUSD() public {
//         address pair = IPancakeFactory(FACTORY).createPair(address(phone), BUSD);
//         assertNotEq(pair, address(0), "Pair creation failed");

//         IPancakePair pairContract = IPancakePair(pair);
//         assertTrue(
//             (pairContract.token0() == address(phone) && pairContract.token1() == BUSD) ||
//             (pairContract.token0() == BUSD && pairContract.token1() == address(phone)),
//             "Tokens not set correctly in pair"
//         );
//     }

//     function testAddLiquidityPhoneWithBUSD() public {
//         address pair = setupPhoneBUSDPair();
//         IPancakePair pairContract = IPancakePair(pair);

//         uint lpBalance = pairContract.balanceOf(testAddress);
//         assertGt(lpBalance, 0, "LP tokens not minted");

//         (uint reserve0, uint reserve1,) = pairContract.getReserves();
//         assertEq(reserve0, 100 ether, "Reserve0 incorrect");
//         assertEq(reserve1, 100 * 10**18, "Reserve1 incorrect");
//     }

//     function testSwapPhoneForBUSDPriceChange() public {
//         address pair = setupPhoneBUSDPair();
//         uint initialPrice = getPrice(pair, address(phone), BUSD);
//         console.log("Initial Price (BUSD per PH, normalized to 18 decimals): %s", initialPrice);

//         phone.approve(ROUTER, 10 ether);
//         address[] memory path = new address[](2);
//         path[0] = address(phone);
//         path[1] = BUSD;

//         IPancakeRouter02(ROUTER).swapExactTokensForTokens(
//             10 ether,
//             0,
//             path,
//             testAddress,
//             block.timestamp + 1000
//         );

//         uint finalPrice = getPrice(pair, address(phone), BUSD);
//         console.log("Final Price (BUSD per PH, normalized to 18 decimals): %s", finalPrice);
//         assertLt(finalPrice, initialPrice, "Price should decrease after selling phoneToken");
//     }

//     // phoneToken-WBNB Pair Tests

//     function testCreatePairPhoneWithWBNB() public {
//         address pair = IPancakeFactory(FACTORY).createPair(address(phone), WBNB);
//         assertNotEq(pair, address(0), "Pair creation failed");

//         IPancakePair pairContract = IPancakePair(pair);
//         assertTrue(
//             (pairContract.token0() == address(phone) && pairContract.token1() == WBNB) ||
//             (pairContract.token0() == WBNB && pairContract.token1() == address(phone)),
//             "Tokens not set correctly in pair"
//         );
//     }

//     function testAddLiquidityPhoneWithWBNB() public {
//         address pair = setupPhoneWBNBPair();
//         IPancakePair pairContract = IPancakePair(pair);

//         uint lpBalance = pairContract.balanceOf(testAddress);
//         assertGt(lpBalance, 0, "LP tokens not minted");
//     }

//     function testSwapPhoneForWBNBPriceChange() public {
//         address pair = setupPhoneWBNBPair();
//         uint initialPrice = getPrice(pair, address(phone), WBNB);
//         console.log("Initial Price (WBNB per PH, normalized to 18 decimals): %s", initialPrice);

//         phone.approve(ROUTER, 10 ether);
//         address[] memory path = new address[](2);
//         path[0] = address(phone);
//         path[1] = WBNB;

//         IPancakeRouter02(ROUTER).swapExactTokensForTokens(
//             10 ether,
//             0,
//             path,
//             testAddress,
//             block.timestamp + 1000
//         );

//         uint finalPrice = getPrice(pair, address(phone), WBNB);
//         console.log("Final Price (WBNB per PH, normalized to 18 decimals): %s", finalPrice);
//         assertLt(finalPrice, initialPrice, "Price should decrease after selling phoneToken");
//     }

//     function testSwapWBNBForPhonePriceChange() public {
//         address pair = setupPhoneWBNBPair();
//         uint initialPrice = getPrice(pair, address(phone), WBNB);
//         console.log("Initial Price (WBNB per PH, normalized to 18 decimals): %s", initialPrice);

//         address[] memory path = new address[](2);
//         path[0] = WBNB;
//         path[1] = address(phone);

//         IPancakeRouter02(ROUTER).swapExactETHForTokens{value: 0.1 ether}(
//             0,
//             path,
//             testAddress,
//             block.timestamp + 1000
//         );

//         uint finalPrice = getPrice(pair, address(phone), WBNB);
//         console.log("Final Price (WBNB per PH, normalized to 18 decimals): %s", finalPrice);
//         assertGt(finalPrice, initialPrice, "Price should increase after buying phoneToken");
//     }
// }