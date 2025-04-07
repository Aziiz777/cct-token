// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/phone.sol"; // Your phoneToken contract
import "@uniswap/v2-core/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PhoneTokenUniswapV2Test is Test {
    // Uniswap V2 mainnet addresses
    address public constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    phoneToken public phone;
    IERC20 public usdc = IERC20(USDC);
    address public testAddress;

    // Allow contract to receive ETH
    receive() external payable {}

    function setUp() public {
        // Fork Ethereum mainnet
        string memory rpcUrl = vm.envString("MAINNET_RPC_URL");
        vm.createFork(rpcUrl);

        // Deploy phoneToken with testAddress as admin
        testAddress = address(this);
        phone = new phoneToken(testAddress);

        // Grant MINTER_ROLE to test contract
        phone.grantRole(phone.MINTER_ROLE(), testAddress);

        // Mint initial phoneToken (within monthly limit)
        phone.mint(testAddress, 1000 ether); // 1000 PH
        assertEq(phone.balanceOf(testAddress), 1000 ether + phone.INITIAL_MINT(), "Initial mint failed");

        // Deal USDC and ETH to test address
        vm.deal(testAddress, 100 ether); // For WETH pair
        deal(USDC, testAddress, 1000 * 10**6); // 1000 USDC (6 decimals)
    }

    // Helper: Calculate price of phoneToken in terms of other token (e.g., USDC or WETH)
    function getPrice(address pair, address token0, address token1) internal view returns (uint256) {
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
        if (token0 == address(phone)) {
            return (reserve1 * 10**18) / reserve0; // Price in token1 (USDC or WETH) per PH, normalized to 18 decimals
        } else {
            return (reserve0 * 10**18) / reserve1; // Price in token0 per PH
        }
    }

    // Helper: phoneToken-USDC pair setup
    function setupPhoneUSDCPair() internal returns (address) {
        address pair = IUniswapV2Factory(FACTORY).createPair(address(phone), USDC);
        //phone.addToWhitelist(pair); // Bypass 1% fee

        phone.approve(ROUTER, 100 ether); // 100 PH
        usdc.approve(ROUTER, 100 * 10**6); // 100 USDC

        IUniswapV2Router02(ROUTER).addLiquidity(
            address(phone),
            USDC,
            100 ether,
            100 * 10**6,
            0,
            0,
            testAddress,
            block.timestamp + 1000
        );
        return pair;
    }

    // Helper: phoneToken-WETH pair setup
    function setupPhoneWETHPair() internal returns (address) {
        address pair = IUniswapV2Factory(FACTORY).createPair(address(phone), WETH);
        phone.addToWhitelist(pair);

        phone.approve(ROUTER, 100 ether);
        IUniswapV2Router02(ROUTER).addLiquidityETH{value: 1 ether}(
            address(phone),
            100 ether,
            0,
            0,
            testAddress,
            block.timestamp + 1000
        );
        return pair;
    }

    // phoneToken-USDC Pair Tests

    function testCreatePairPhoneWithUSDC() public {
        address pair = IUniswapV2Factory(FACTORY).createPair(address(phone), USDC);
        assertNotEq(pair, address(0), "Pair creation failed");

        IUniswapV2Pair pairContract = IUniswapV2Pair(pair);
        assertTrue(
            (pairContract.token0() == address(phone) && pairContract.token1() == USDC) ||
            (pairContract.token0() == USDC && pairContract.token1() == address(phone)),
            "Tokens not set correctly in pair"
        );
    }

    function testAddLiquidityPhoneWithUSDC() public {
        address pair = setupPhoneUSDCPair();
        IUniswapV2Pair pairContract = IUniswapV2Pair(pair);

        uint lpBalance = pairContract.balanceOf(testAddress);
        assertGt(lpBalance, 0, "LP tokens not minted");

        (uint reserve0, uint reserve1,) = pairContract.getReserves();
        assertEq(reserve0, 100 ether, "Reserve0 incorrect");
        assertEq(reserve1, 100 * 10**6, "Reserve1 incorrect");
    }

    function testSwapPhoneForUSDCPriceChange() public {
    address pair = setupPhoneUSDCPair();
    uint initialPrice = getPrice(pair, address(phone), USDC);
    emit log_named_uint("Initial Price (USDC per PH, normalized to 18 decimals)", initialPrice);

    phone.approve(ROUTER, 10 ether);
    address[] memory path = new address[](2);
    path[0] = address(phone);
    path[1] = USDC;

    IUniswapV2Router02(ROUTER).swapExactTokensForTokens(
        10 ether,
        0,
        path,
        testAddress,
        block.timestamp + 1000
    );

    uint finalPrice = getPrice(pair, address(phone), USDC);
    emit log_named_uint("Final Price (USDC per PH, normalized to 18 decimals)", finalPrice); // Ensure this runs
    assertLt(finalPrice, initialPrice, "Price should decrease after selling phoneToken");
}

    // phoneToken-WETH Pair Tests

    function testCreatePairPhoneWithWETH() public {
        address pair = IUniswapV2Factory(FACTORY).createPair(address(phone), WETH);
        assertNotEq(pair, address(0), "Pair creation failed");

        IUniswapV2Pair pairContract = IUniswapV2Pair(pair);
        assertTrue(
            (pairContract.token0() == address(phone) && pairContract.token1() == WETH) ||
            (pairContract.token0() == WETH && pairContract.token1() == address(phone)),
            "Tokens not set correctly in pair"
        );
    }

    function testAddLiquidityPhoneWithWETH() public {
        address pair = setupPhoneWETHPair();
        IUniswapV2Pair pairContract = IUniswapV2Pair(pair);

        uint lpBalance = pairContract.balanceOf(testAddress);
        assertGt(lpBalance, 0, "LP tokens not minted");
    }

    function testSwapPhoneForETHPriceChange() public {
        address pair = setupPhoneWETHPair();
        uint initialPrice = getPrice(pair, address(phone), WETH);
        emit log_named_uint("Initial Price (ETH per PH, normalized to 18 decimals)", initialPrice);

        phone.approve(ROUTER, 10 ether);
        address[] memory path = new address[](2);
        path[0] = address(phone);
        path[1] = WETH;

        IUniswapV2Router02(ROUTER).swapExactTokensForETH(
            10 ether, // 10 PH
            0,
            path,
            testAddress,
            block.timestamp + 1000
        );

        uint finalPrice = getPrice(pair, address(phone), WETH);
        emit log_named_uint("Final Price (ETH per PH, normalized to 18 decimals)", finalPrice);
        assertLt(finalPrice, initialPrice, "Price should decrease after selling phoneToken");
    }

    function testSwapETHForPhonePriceChange() public {
        address pair = setupPhoneWETHPair();
        uint initialPrice = getPrice(pair, address(phone), WETH);
        emit log_named_uint("Initial Price (ETH per PH, normalized to 18 decimals)", initialPrice);

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(phone);

        IUniswapV2Router02(ROUTER).swapExactETHForTokens{value: 0.1 ether}(
            0,
            path,
            testAddress,
            block.timestamp + 1000
        );

        uint finalPrice = getPrice(pair, address(phone), WETH);
        emit log_named_uint("Final Price (ETH per PH, normalized to 18 decimals)", finalPrice);
        assertGt(finalPrice, initialPrice, "Price should increase after buying phoneToken");
    }
}