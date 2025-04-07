// test/CCIPv1_5ForkBurnMintPoolFork.t.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, Vm } from "forge-std/Test.sol";
import { phoneToken} from "./phone.sol";
import "forge-std/console.sol";
import {CCIPLocalSimulatorFork,IRouterFork, Register} from "@chainlink-local/local/src/ccip/CCIPLocalSimulatorFork.sol";
import { BurnMintTokenPool, TokenPool } from "@chainlink-local/contracts-ccip/src/v0.8/ccip/pools/BurnMintTokenPool.sol";
import {IPoolPriorTo1_5} from "@chainlink-local/contracts-ccip/src/v0.8/ccip/interfaces/IPoolPriorTo1_5.sol";
import {IPoolV1} from "@chainlink-local/contracts-ccip/src/v0.8/ccip/interfaces/IPool.sol";
import { LockReleaseTokenPool } from "@chainlink-local/contracts-ccip/src/v0.8/ccip/pools/LockReleaseTokenPool.sol"; // not used in this test
import { IBurnMintERC20 } from "@chainlink-local/contracts-ccip/src/v0.8/shared/token/ERC20/IBurnMintERC20.sol";
import { RegistryModuleOwnerCustom } from "@chainlink-local/contracts-ccip/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import { TokenAdminRegistry } from "@chainlink-local/contracts-ccip/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import { RateLimiter } from "@chainlink-local/contracts-ccip/src/v0.8/ccip/libraries/RateLimiter.sol";
import { IRouterClient } from "@chainlink-local/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import { Client } from "@chainlink-local/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

import { ERC20, ERC20Burnable, IERC20 } from "@chainlink-local/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { AccessControl } from "@chainlink-local/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/access/AccessControl.sol";

contract MockERC20BurnAndMintToken is IBurnMintERC20, ERC20Burnable, AccessControl {
  address internal immutable i_CCIPAdmin;
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  constructor() ERC20("phone", "ph") {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
    _grantRole(BURNER_ROLE, msg.sender);
    i_CCIPAdmin = msg.sender;
  }

  function mint(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
    _mint(account, amount);
  }

  function burn(uint256 amount) public override(IBurnMintERC20, ERC20Burnable) onlyRole(BURNER_ROLE) {
    super.burn(amount);
  }

  function burnFrom(
    address account,
    uint256 amount
  ) public override(IBurnMintERC20, ERC20Burnable) onlyRole(BURNER_ROLE) {
    super.burnFrom(account, amount);
  }

  function burn(address account, uint256 amount) public virtual override {
    burnFrom(account, amount);
  }

  function getCCIPAdmin() public view returns (address) {
    return i_CCIPAdmin;
  }
}

contract CCIPv1_5BurnMintPoolFork is Test {
  CCIPLocalSimulatorFork public ccipLocalSimulatorFork;
  phoneToken public mockERC20TokenEthSepolia;
  phoneToken public mockERC20TokenBaseSepolia;
  phoneToken public mockERC20TokenOptimismSepolia;
  phoneToken public mockERC20TokenZkSyncSepolia;
  phoneToken public mockERC20TokenArbitrumSepolia;
  BurnMintTokenPool public burnMintTokenPoolEthSepolia;
  BurnMintTokenPool public burnMintTokenPoolBaseSepolia;
  BurnMintTokenPool public burnMintTokenPoolOptimismSepolia;
  BurnMintTokenPool public burnMintTokenPoolZkSyncSepolia;
  BurnMintTokenPool public burnMintTokenPoolArbitrumSepolia;

  Register.NetworkDetails ethSepoliaNetworkDetails;
  Register.NetworkDetails baseSepoliaNetworkDetails;
  Register.NetworkDetails optimismSepoliaNetworkDetails;
  Register.NetworkDetails zkSyncSepoliaDetails;
  Register.NetworkDetails arbitrumSepoliaDetails;

  uint256 ethSepoliaFork;
  uint256 baseSepoliaFork;
  uint256 optimismSepoliaFork;
  uint256 zkSyncSepoliaFork;
  uint256 arbitrumSepoliaFork;

  address aliceEth;
  address aliceBase;
  address aliceOptimism;
  address aliceZk;
  address aliceArbitrum;

function setUp() public {
    // Define unique deployers for each fork
    aliceEth = makeAddr("aliceEth");
    aliceBase = makeAddr("aliceBase");
    aliceOptimism = makeAddr("aliceOptimism");
    aliceZk = makeAddr("aliceZk");
    aliceArbitrum = makeAddr("aliceArbitrum");

    console.log("alice Eth Address:",aliceEth);
    console.log("alice base Address:",aliceBase);
    console.log("alice optimism Address:",aliceOptimism);
    console.log("alice zksync Address:",aliceZk);
    console.log("alice Arbitrum Address:",aliceZk);
    // Create forks
    string memory ETHEREUM_SEPOLIA_RPC_URL = vm.envString("ETHEREUM_SEPOLIA_RPC_URL");
    string memory BASE_SEPOLIA_RPC_URL = vm.envString("BASE_SEPOLIA_RPC_URL");
    string memory OPTIMISM_SEPOLIA_RPC_URL = vm.envString("OPTIMISM_SEPOLIA_RPC_URL");
    string memory ZKSYNC_SEPOLIA_RPC_URL = vm.envString("ZKSYNC_SEPOLIA_RPC_URL");
    string memory ARBITRUM_SEPOLIA_RPC_URL = vm.envString("ARBITRUM_SEPOLIA_RPC_URL");

    ethSepoliaFork = vm.createFork(ETHEREUM_SEPOLIA_RPC_URL);
    baseSepoliaFork = vm.createFork(BASE_SEPOLIA_RPC_URL);
    optimismSepoliaFork = vm.createFork(OPTIMISM_SEPOLIA_RPC_URL);
    zkSyncSepoliaFork = vm.createFork(ZKSYNC_SEPOLIA_RPC_URL);
    arbitrumSepoliaFork = vm.createFork(ARBITRUM_SEPOLIA_RPC_URL);

    // Deploy tokens and CCIP simulator on each fork with unique deployers
    vm.selectFork(ethSepoliaFork);
    vm.startPrank(aliceEth);
    vm.deal(aliceEth, 1 ether);
    mockERC20TokenEthSepolia = new phoneToken(address(aliceEth));
    // phoneToken(mockERC20TokenEthSepolia).initialize(address(aliceEth));
    console.log("Eth Sepolia Token Deployed:", address(mockERC20TokenEthSepolia));
    ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
    vm.makePersistent(address(ccipLocalSimulatorFork));
    console.log("CCIP Simulator Deployed:", address(ccipLocalSimulatorFork));
    vm.stopPrank();

    vm.selectFork(baseSepoliaFork);
    vm.startPrank(aliceBase);
    vm.deal(aliceBase, 1 ether);
    mockERC20TokenBaseSepolia = new phoneToken(address(aliceBase));
    // phoneToken(mockERC20TokenBaseSepolia).initialize(address(aliceBase));
    console.log("Base Sepolia Token Deployed:", address(mockERC20TokenBaseSepolia));
    vm.stopPrank();

    vm.selectFork(optimismSepoliaFork);
    vm.startPrank(aliceOptimism);
    vm.deal(aliceOptimism, 1 ether);
    mockERC20TokenOptimismSepolia = new phoneToken(address(aliceOptimism));
    // phoneToken(mockERC20TokenOptimismSepolia).initialize(address(aliceOptimism));
    console.log("Optimism Sepolia Token Deployed:", address(mockERC20TokenOptimismSepolia));
    vm.stopPrank();

    vm.selectFork(zkSyncSepoliaFork);
    vm.startPrank(aliceZk);
    vm.deal(aliceZk, 1 ether);
    mockERC20TokenZkSyncSepolia = new phoneToken(address(aliceZk));
    // phoneToken(mockERC20TokenZkSyncSepolia).initialize(address(aliceZk));
    console.log("zkSync Sepolia Token Deployed:", address(mockERC20TokenZkSyncSepolia));

    vm.stopPrank();

    vm.selectFork(arbitrumSepoliaFork);
    vm.startPrank(aliceArbitrum);
    vm.deal(aliceArbitrum, 1 ether);
    mockERC20TokenArbitrumSepolia = new phoneToken(address(aliceArbitrum));
    // phoneToken(mockERC20TokenArbitrumSepolia).initialize(address(aliceArbitrum));
    console.log("zkSync Sepolia Token Deployed:", address(mockERC20TokenArbitrumSepolia));

    vm.stopPrank();
}

// function test_forkSupportNewCCIPToken() public {
//     // Step 3) Deploy BurnMintTokenPool on Ethereum Sepolia
//     vm.selectFork(ethSepoliaFork);
//     ethSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
//     address[] memory allowlist = new address[](0);
//     uint8 localTokenDecimals = 18;

//     vm.startPrank(alice);
//     burnMintTokenPoolEthSepolia = new BurnMintTokenPool(
//       IBurnMintERC20(address(mockERC20TokenEthSepolia)),
//       localTokenDecimals,
//       allowlist,
//       ethSepoliaNetworkDetails.rmnProxyAddress,
//       ethSepoliaNetworkDetails.routerAddress
//     );
//     vm.stopPrank();

//     // Step 4) Deploy BurnMintTokenPool on Base Sepolia
//     vm.selectFork(baseSepoliaFork);
//     baseSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);

//     vm.startPrank(alice);
//     burnMintTokenPoolBaseSepolia = new BurnMintTokenPool(
//       IBurnMintERC20(address(mockERC20TokenBaseSepolia)),
//       localTokenDecimals,
//       allowlist,
//       baseSepoliaNetworkDetails.rmnProxyAddress,
//       baseSepoliaNetworkDetails.routerAddress
//     );
//     vm.stopPrank();

//     // Step 5) Grant Mint and Burn roles to BurnMintTokenPool on Ethereum Sepolia
//     vm.selectFork(ethSepoliaFork);

//     vm.startPrank(alice);
//     mockERC20TokenEthSepolia.grantRole(mockERC20TokenEthSepolia.MINTER_ROLE(), address(burnMintTokenPoolEthSepolia));
//     mockERC20TokenEthSepolia.grantRole(mockERC20TokenEthSepolia.BURNER_ROLE(), address(burnMintTokenPoolEthSepolia));
//     vm.stopPrank();

//     // Step 6) Grant Mint and Burn roles to BurnMintTokenPool on Base Sepolia
//     vm.selectFork(baseSepoliaFork);

//     vm.startPrank(alice);
//     mockERC20TokenBaseSepolia.grantRole(mockERC20TokenBaseSepolia.MINTER_ROLE(), address(burnMintTokenPoolBaseSepolia));
//     mockERC20TokenBaseSepolia.grantRole(mockERC20TokenBaseSepolia.BURNER_ROLE(), address(burnMintTokenPoolBaseSepolia));
//     vm.stopPrank();

//     // Step 7) Claim Admin role on Ethereum Sepolia
//     vm.selectFork(ethSepoliaFork);

//     RegistryModuleOwnerCustom registryModuleOwnerCustomEthSepolia = RegistryModuleOwnerCustom(
//       ethSepoliaNetworkDetails.registryModuleOwnerCustomAddress
//     );

//     vm.startPrank(alice);
//     registryModuleOwnerCustomEthSepolia.registerAdminViaGetCCIPAdmin(address(mockERC20TokenEthSepolia));
//     vm.stopPrank();

//     // Step 8) Claim Admin role on Base Sepolia
//     vm.selectFork(baseSepoliaFork);

//     RegistryModuleOwnerCustom registryModuleOwnerCustomBaseSepolia = RegistryModuleOwnerCustom(
//       baseSepoliaNetworkDetails.registryModuleOwnerCustomAddress
//     );

//     vm.startPrank(alice);
//     registryModuleOwnerCustomBaseSepolia.registerAdminViaGetCCIPAdmin(address(mockERC20TokenBaseSepolia));
//     vm.stopPrank();

//     // Step 9) Accept Admin role on Ethereum Sepolia
//     vm.selectFork(ethSepoliaFork);

//     TokenAdminRegistry tokenAdminRegistryEthSepolia = TokenAdminRegistry(
//       ethSepoliaNetworkDetails.tokenAdminRegistryAddress
//     );

//     vm.startPrank(alice);
//     tokenAdminRegistryEthSepolia.acceptAdminRole(address(mockERC20TokenEthSepolia));
//     vm.stopPrank();

//     // Step 10) Accept Admin role on Base Sepolia
//     vm.selectFork(baseSepoliaFork);

//     TokenAdminRegistry tokenAdminRegistryBaseSepolia = TokenAdminRegistry(
//       baseSepoliaNetworkDetails.tokenAdminRegistryAddress
//     );

//     vm.startPrank(alice);
//     tokenAdminRegistryBaseSepolia.acceptAdminRole(address(mockERC20TokenBaseSepolia));
//     vm.stopPrank();

//     // Step 11) Link token to pool on Ethereum Sepolia
//     vm.selectFork(ethSepoliaFork);

//     vm.startPrank(alice);
//     tokenAdminRegistryEthSepolia.setPool(address(mockERC20TokenEthSepolia), address(burnMintTokenPoolEthSepolia));
//     vm.stopPrank();

//     // Step 12) Link token to pool on Base Sepolia
//     vm.selectFork(baseSepoliaFork);

//     vm.startPrank(alice);
//     tokenAdminRegistryBaseSepolia.setPool(address(mockERC20TokenBaseSepolia), address(burnMintTokenPoolBaseSepolia));
//     vm.stopPrank();

//     // Step 13) Configure Token Pool on Ethereum Sepolia
//     vm.selectFork(ethSepoliaFork);

//     vm.startPrank(alice);
//     TokenPool.ChainUpdate[] memory chains = new TokenPool.ChainUpdate[](1);
//     bytes[] memory remotePoolAddressesEthSepolia = new bytes[](1);
//     remotePoolAddressesEthSepolia[0] = abi.encode(address(burnMintTokenPoolEthSepolia));
//     chains[0] = TokenPool.ChainUpdate({
//       remoteChainSelector: baseSepoliaNetworkDetails.chainSelector,
//       remotePoolAddresses: remotePoolAddressesEthSepolia,
//       remoteTokenAddress: abi.encode(address(mockERC20TokenBaseSepolia)),
//       outboundRateLimiterConfig: RateLimiter.Config({ isEnabled: true, capacity: 100_000, rate: 167 }),
//       inboundRateLimiterConfig: RateLimiter.Config({ isEnabled: true, capacity: 100_000, rate: 167 })
//     });
//     uint64[] memory remoteChainSelectorsToRemove = new uint64[](0);
//     burnMintTokenPoolEthSepolia.applyChainUpdates(remoteChainSelectorsToRemove, chains);
//     vm.stopPrank();

//     // Step 14) Configure Token Pool on Base Sepolia
//     vm.selectFork(baseSepoliaFork);

//     vm.startPrank(alice);
//     chains = new TokenPool.ChainUpdate[](1);
//     bytes[] memory remotePoolAddressesBaseSepolia = new bytes[](1);
//     remotePoolAddressesBaseSepolia[0] = abi.encode(address(burnMintTokenPoolEthSepolia));
//     chains[0] = TokenPool.ChainUpdate({
//       remoteChainSelector: ethSepoliaNetworkDetails.chainSelector,
//       remotePoolAddresses: remotePoolAddressesBaseSepolia,
//       remoteTokenAddress: abi.encode(address(mockERC20TokenEthSepolia)),
//       outboundRateLimiterConfig: RateLimiter.Config({ isEnabled: true, capacity: 100_000, rate: 167 }),
//       inboundRateLimiterConfig: RateLimiter.Config({ isEnabled: true, capacity: 100_000, rate: 167 })
//     });
//     burnMintTokenPoolBaseSepolia.applyChainUpdates(remoteChainSelectorsToRemove, chains);
//     vm.stopPrank();

//     // Step 15) Mint tokens on Ethereum Sepolia and transfer them to Base Sepolia
//     vm.selectFork(ethSepoliaFork);

//     address linkSepolia = ethSepoliaNetworkDetails.linkAddress;
//     ccipLocalSimulatorFork.requestLinkFromFaucet(address(alice), 20 ether);

//     uint256 amountToSend = 100;
//     Client.EVMTokenAmount[] memory tokenToSendDetails = new Client.EVMTokenAmount[](1);
//     Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({
//       token: address(mockERC20TokenEthSepolia),
//       amount: amountToSend
//     });
//     tokenToSendDetails[0] = tokenAmount;

//     vm.startPrank(alice);
//     mockERC20TokenEthSepolia.mint(address(alice), amountToSend);

//     mockERC20TokenEthSepolia.approve(ethSepoliaNetworkDetails.routerAddress, amountToSend);
//     IERC20(linkSepolia).approve(ethSepoliaNetworkDetails.routerAddress, 20 ether);

//     uint256 balanceOfAliceBeforeEthSepolia = mockERC20TokenEthSepolia.balanceOf(alice);

//     IRouterClient routerEthSepolia = IRouterClient(ethSepoliaNetworkDetails.routerAddress);
//     routerEthSepolia.ccipSend(
//       baseSepoliaNetworkDetails.chainSelector,
//       Client.EVM2AnyMessage({
//         receiver: abi.encode(address(alice)),
//         data: "",
//         tokenAmounts: tokenToSendDetails,
//         extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({ gasLimit: 0 })),
//         feeToken: linkSepolia
//       })
//     );

//     uint256 balanceOfAliceAfterEthSepolia = mockERC20TokenEthSepolia.balanceOf(alice);
//     vm.stopPrank();

//     assertEq(balanceOfAliceAfterEthSepolia, balanceOfAliceBeforeEthSepolia - amountToSend);

//     ccipLocalSimulatorFork.switchChainAndRouteMessage(baseSepoliaFork);

//     uint256 balanceOfAliceAfterBaseSepolia = mockERC20TokenBaseSepolia.balanceOf(alice);
//     assertEq(balanceOfAliceAfterBaseSepolia, amountToSend);
//   }



function test_forkSupportNewCCIPToken2() public {
    // Steps 1-3: Deploy BurnMintTokenPools with unique deployers
    vm.selectFork(ethSepoliaFork);
    ethSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
    vm.selectFork(baseSepoliaFork);
    baseSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
    vm.selectFork(optimismSepoliaFork);
    optimismSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
    vm.selectFork(zkSyncSepoliaFork);
    zkSyncSepoliaDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
    vm.selectFork(arbitrumSepoliaFork);
    arbitrumSepoliaDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);

    burnMintTokenPoolEthSepolia = deployTokenPool(
        ethSepoliaFork,
        aliceEth,
        address(mockERC20TokenEthSepolia),
        ethSepoliaNetworkDetails.rmnProxyAddress,
        ethSepoliaNetworkDetails.routerAddress
    );
    phoneToken(mockERC20TokenEthSepolia).addToWhitelist(address(burnMintTokenPoolEthSepolia));
    burnMintTokenPoolBaseSepolia = deployTokenPool(
        baseSepoliaFork,
        aliceBase,
        address(mockERC20TokenBaseSepolia),
        baseSepoliaNetworkDetails.rmnProxyAddress,
        baseSepoliaNetworkDetails.routerAddress
    );
    phoneToken(mockERC20TokenBaseSepolia).addToWhitelist(address(burnMintTokenPoolBaseSepolia));

    burnMintTokenPoolOptimismSepolia = deployTokenPool(
        optimismSepoliaFork,
        aliceOptimism,
        address(mockERC20TokenOptimismSepolia),
        optimismSepoliaNetworkDetails.rmnProxyAddress,
        optimismSepoliaNetworkDetails.routerAddress
    );
    phoneToken(mockERC20TokenOptimismSepolia).addToWhitelist(address(burnMintTokenPoolOptimismSepolia));


    burnMintTokenPoolZkSyncSepolia = deployTokenPool(
        zkSyncSepoliaFork,
        aliceZk,
        address(mockERC20TokenZkSyncSepolia),
        zkSyncSepoliaDetails.rmnProxyAddress,
        zkSyncSepoliaDetails.routerAddress
    );
    phoneToken(mockERC20TokenZkSyncSepolia).addToWhitelist(address(burnMintTokenPoolZkSyncSepolia));

    burnMintTokenPoolArbitrumSepolia = deployTokenPool(
        arbitrumSepoliaFork,
        aliceArbitrum,
        address(mockERC20TokenArbitrumSepolia),
        arbitrumSepoliaDetails.rmnProxyAddress,
        arbitrumSepoliaDetails.routerAddress
    );
    phoneToken(mockERC20TokenArbitrumSepolia).addToWhitelist(address(burnMintTokenPoolArbitrumSepolia));


    // Verify unique addresses
    require(address(burnMintTokenPoolEthSepolia) != address(burnMintTokenPoolBaseSepolia), "Eth and Base pools must differ");
    require(address(burnMintTokenPoolEthSepolia) != address(burnMintTokenPoolOptimismSepolia), "Eth and Optimism pools must differ");
    require(address(burnMintTokenPoolEthSepolia) != address(burnMintTokenPoolZkSyncSepolia), "Eth and ZkSync pools must differ");
    require(address(burnMintTokenPoolEthSepolia) != address(burnMintTokenPoolArbitrumSepolia), "Eth and Arbitrum pools must differ");

    require(address(burnMintTokenPoolBaseSepolia) != address(burnMintTokenPoolOptimismSepolia), "Base and Optimism pools must differ");
    require(address(burnMintTokenPoolBaseSepolia) != address(burnMintTokenPoolZkSyncSepolia), "Base and ZkSync pools must differ");
    require(address(burnMintTokenPoolZkSyncSepolia) != address(burnMintTokenPoolOptimismSepolia), "ZkSync and Optimism pools must differ");


    require(address(mockERC20TokenEthSepolia) != address(mockERC20TokenBaseSepolia), "Eth and Base tokens must differ");
    require(address(mockERC20TokenEthSepolia) != address(mockERC20TokenOptimismSepolia), "Eth and Optimism tokens must differ");
    require(address(mockERC20TokenEthSepolia) != address(mockERC20TokenZkSyncSepolia), "Eth and ZkSync tokens must differ");
    require(address(mockERC20TokenEthSepolia) != address(mockERC20TokenArbitrumSepolia), "Eth and Arbitrum tokens must differ");

    require(address(mockERC20TokenBaseSepolia) != address(mockERC20TokenOptimismSepolia), "Base and Optimism tokens must differ");
    require(address(mockERC20TokenBaseSepolia) != address(mockERC20TokenZkSyncSepolia), "Base and ZkSync tokens must differ");
    require(address(mockERC20TokenZkSyncSepolia) != address(mockERC20TokenOptimismSepolia), "ZkSync and Optimism tokens must differ");
    // require(address(mockERC20TokenBaseSepolia) != address(mockERC20TokenOptimismSepolia), "Base and Optimism tokens must differ");

 // Step 4: Grant roles
    grantRoles(ethSepoliaFork, aliceEth, address(mockERC20TokenEthSepolia), address(burnMintTokenPoolEthSepolia));
    grantRoles(baseSepoliaFork, aliceBase, address(mockERC20TokenBaseSepolia), address(burnMintTokenPoolBaseSepolia));
    grantRoles(optimismSepoliaFork, aliceOptimism, address(mockERC20TokenOptimismSepolia), address(burnMintTokenPoolOptimismSepolia));
    grantRoles(zkSyncSepoliaFork, aliceZk, address(mockERC20TokenZkSyncSepolia), address(burnMintTokenPoolZkSyncSepolia));
    grantRoles(arbitrumSepoliaFork, aliceArbitrum, address(mockERC20TokenArbitrumSepolia), address(burnMintTokenPoolArbitrumSepolia));

    // Steps 8-16: Admin setup
    setupAdminAndPool(
        ethSepoliaFork,
        aliceEth,
        address(mockERC20TokenEthSepolia),
        address(burnMintTokenPoolEthSepolia),
        ethSepoliaNetworkDetails.registryModuleOwnerCustomAddress,
        ethSepoliaNetworkDetails.tokenAdminRegistryAddress
    );
    setupAdminAndPool(
        baseSepoliaFork,
        aliceBase,
        address(mockERC20TokenBaseSepolia),
        address(burnMintTokenPoolBaseSepolia),
        baseSepoliaNetworkDetails.registryModuleOwnerCustomAddress,
        baseSepoliaNetworkDetails.tokenAdminRegistryAddress
    );
    setupAdminAndPool(
        optimismSepoliaFork,
        aliceOptimism,
        address(mockERC20TokenOptimismSepolia),
        address(burnMintTokenPoolOptimismSepolia),
        optimismSepoliaNetworkDetails.registryModuleOwnerCustomAddress,
        optimismSepoliaNetworkDetails.tokenAdminRegistryAddress
    );
    setupAdminAndPool(
        zkSyncSepoliaFork,
        aliceZk,
        address(mockERC20TokenZkSyncSepolia),
        address(burnMintTokenPoolZkSyncSepolia),
        zkSyncSepoliaDetails.registryModuleOwnerCustomAddress,
        zkSyncSepoliaDetails.tokenAdminRegistryAddress
    );
    setupAdminAndPool(
        arbitrumSepoliaFork,
        aliceArbitrum,
        address(mockERC20TokenArbitrumSepolia),
        address(burnMintTokenPoolArbitrumSepolia),
        arbitrumSepoliaDetails.registryModuleOwnerCustomAddress,
        arbitrumSepoliaDetails.tokenAdminRegistryAddress
    );

    // Route the message with detailed debug
    // vm.selectFork(optimismSepoliaFork);
    // address optimismRouter = optimismSepoliaNetworkDetails.routerAddress;
    // console.log("Optimism Sepolia Router Address:", optimismRouter);
    // console.log("Optimism Sepolia chain id :", block.chainid);
    // IRouterFork.OffRamp[] memory offRampsOpt = IRouterFork(address(optimismRouter)).getOffRamps();
    // console.log("Optimism Sepolia OffRamps Count:", offRampsOpt.length);
    // for (uint256 i = 0; i < offRampsOpt.length; i++) {
    //     console.log("OffRamp", i, "Source Chain Selector:", offRampsOpt[i].sourceChainSelector);
    //     console.log("OffRamp", i, "Address:", offRampsOpt[i].offRamp);
    // }

    // Step 5: Configure Eth Sepolia pool with verification
    uint64[] memory ethRemoteChains = new uint64[](4);
    address[] memory ethRemotePools = new address[](4);
    address[] memory ethRemoteTokens = new address[](4);
    ethRemoteChains[0] = baseSepoliaNetworkDetails.chainSelector;
    ethRemoteChains[1] = optimismSepoliaNetworkDetails.chainSelector;
    ethRemoteChains[2] = zkSyncSepoliaDetails.chainSelector;
    ethRemoteChains[3] = arbitrumSepoliaDetails.chainSelector;
    ethRemotePools[0] = address(burnMintTokenPoolBaseSepolia);
    ethRemotePools[1] = address(burnMintTokenPoolOptimismSepolia);
    ethRemotePools[2] = address(burnMintTokenPoolZkSyncSepolia);
    ethRemotePools[3] = address(burnMintTokenPoolArbitrumSepolia);
    ethRemoteTokens[0] = address(mockERC20TokenBaseSepolia);
    ethRemoteTokens[1] = address(mockERC20TokenOptimismSepolia);
    ethRemoteTokens[2] = address(mockERC20TokenZkSyncSepolia);
    ethRemoteTokens[3] = address(mockERC20TokenArbitrumSepolia);
    configurePool(ethSepoliaFork, aliceEth, address(burnMintTokenPoolEthSepolia), ethRemoteChains, ethRemotePools, ethRemoteTokens);

    // Verify Eth Sepolia pool configuration
    console.log("Verifying Eth Sepolia Pool Configuration:");
    for (uint256 i = 0; i < ethRemoteChains.length; i++) {
        bytes[] memory remotePools = IPoolPriorTo1_5(address(burnMintTokenPoolEthSepolia)).getRemotePools(ethRemoteChains[i]);
        console.log("Chain Selector:", ethRemoteChains[i]);
        console.log("Number of Remote Pools:", remotePools.length);
        if (remotePools.length > 0) {
            for (uint256 j = 0; j < remotePools.length; j++) {
                address decodedPool = abi.decode(remotePools[j], (address));
                console.log("Decoded Remote Pool", j, ":", decodedPool);
            }
        } else {
            console.log("No remote pools configured for this selector");
        }
    }
    console.log("Eth Sepolia Pool Config Verification:");
    console.log("Configured Base Chain Selector:", ethRemoteChains[0]);
    console.log("Configured Base Pool Address:", ethRemotePools[0]);
    console.log("Configured Optimism Chain Selector:", ethRemoteChains[1]);
    console.log("Configured Optimism Pool Address:", ethRemotePools[1]);
    console.log("Configured zkSync Chain Selector:", ethRemoteChains[2]);
    console.log("Configured zkSync Pool Address:", ethRemotePools[2]);
    console.log("Configured Arbitrum Chain Selector:", ethRemoteChains[3]);
    console.log("Configured Arbitrum Pool Address:", ethRemotePools[3]);

    // Verify Eth Sepolia pool configuration
    vm.selectFork(ethSepoliaFork);
    console.log("Eth Sepolia Pool - Verifying Config for Base:");
    console.log("Expected Base Chain Selector:", baseSepoliaNetworkDetails.chainSelector);
    console.log("Expected Base Pool Address:", address(burnMintTokenPoolBaseSepolia));

    // Step 6: Configure Base Sepolia pool
    uint64[] memory baseRemoteChains = new uint64[](1);
    address[] memory baseRemotePools = new address[](1);
    address[] memory baseRemoteTokens = new address[](1);
    baseRemoteChains[0] = ethSepoliaNetworkDetails.chainSelector;
    baseRemotePools[0] = address(burnMintTokenPoolEthSepolia);
    baseRemoteTokens[0] = address(mockERC20TokenEthSepolia);
    configurePool(baseSepoliaFork, aliceBase, address(burnMintTokenPoolBaseSepolia), baseRemoteChains, baseRemotePools, baseRemoteTokens);

    // Step 7: Configure Optimism Sepolia pool
    uint64[] memory optRemoteChains = new uint64[](1);
    address[] memory optRemotePools = new address[](1);
    address[] memory optRemoteTokens = new address[](1);
    optRemoteChains[0] = ethSepoliaNetworkDetails.chainSelector;
    optRemotePools[0] = address(burnMintTokenPoolEthSepolia);
    optRemoteTokens[0] = address(mockERC20TokenEthSepolia);
    configurePool(optimismSepoliaFork, aliceOptimism, address(burnMintTokenPoolOptimismSepolia), optRemoteChains, optRemotePools, optRemoteTokens);

    // Step 8: Configure ZkSync Sepolia pool
    uint64[] memory zkRemoteChains = new uint64[](1);
    address[] memory zkRemotePools = new address[](1);
    address[] memory zkRemoteTokens = new address[](1);
    zkRemoteChains[0] = ethSepoliaNetworkDetails.chainSelector;
    zkRemotePools[0] = address(burnMintTokenPoolEthSepolia);
    zkRemoteTokens[0] = address(mockERC20TokenEthSepolia);
    configurePool(zkSyncSepoliaFork, aliceZk, address(burnMintTokenPoolZkSyncSepolia), zkRemoteChains, zkRemotePools, zkRemoteTokens);

    // Step 8: Configure Arbitrum Sepolia pool
    uint64[] memory arbRemoteChains = new uint64[](1);
    address[] memory arbRemotePools = new address[](1);
    address[] memory arbRemoteTokens = new address[](1);
    arbRemoteChains[0] = ethSepoliaNetworkDetails.chainSelector;
    arbRemotePools[0] = address(burnMintTokenPoolEthSepolia);
    arbRemoteTokens[0] = address(mockERC20TokenEthSepolia);
    configurePool(arbitrumSepoliaFork, aliceArbitrum, address(burnMintTokenPoolArbitrumSepolia), arbRemoteChains, arbRemotePools, arbRemoteTokens);


    vm.selectFork(ethSepoliaFork);
    vm.selectFork(ethSepoliaFork);
    bytes[] memory remotePools = IPoolPriorTo1_5(address(burnMintTokenPoolEthSepolia)).getRemotePools(optimismSepoliaNetworkDetails.chainSelector);
    console.log("Eth Sepolia Pools - Remote Pools After Initial Config length: ",remotePools.length);
    if (remotePools.length > 0) {
        for (uint256 i = 0; i < remotePools.length; i++) {
            address decodedPool = abi.decode(remotePools[i], (address));
            console.log("Decoded Remote Pool", i, ":", decodedPool);
        }
    } else {
        console.log("No remote pools configured for Optimism selector");
    }
    // Step 17: Send tokens from Eth Sepolia to Base and Optimism and ZkSync,arbitrum, then back
    vm.selectFork(ethSepoliaFork);
    ccipLocalSimulatorFork.requestLinkFromFaucet(aliceEth, 20 ether);
    vm.startPrank(aliceEth);
    uint256 amountToSend = 100;
    mockERC20TokenEthSepolia.mint(aliceEth, amountToSend * 4);
    console.log("Eth Sepolia - Initial Alice Balance:", mockERC20TokenEthSepolia.balanceOf(aliceEth));
    vm.selectFork(baseSepoliaFork);
    console.log("Base Sepolia - Initial Alice Balance:", mockERC20TokenBaseSepolia.balanceOf(aliceBase));
    vm.selectFork(optimismSepoliaFork);
    console.log("Optimism Sepolia - Initial Alice Balance:", mockERC20TokenOptimismSepolia.balanceOf(aliceOptimism));
    vm.selectFork(ethSepoliaFork);

    uint256 balanceBeforeEth = mockERC20TokenEthSepolia.balanceOf(aliceEth);

    // Eth -> Base
    bytes32 messageIdBase = sendTokens(
        ethSepoliaFork,
        aliceEth,
        ethSepoliaNetworkDetails.routerAddress,
        address(mockERC20TokenEthSepolia),
        address(0), // Pass address(0) instead of linkAddress; ignored in function
        baseSepoliaNetworkDetails.chainSelector,
        aliceBase,
        amountToSend
    );

    console.log("Base Transfer Message ID (Eth -> Base):", uint256(messageIdBase));
    console.log("Eth Sepolia - After Base Transfer Alice Balance:", mockERC20TokenEthSepolia.balanceOf(aliceEth));

    ccipLocalSimulatorFork.switchChainAndRouteMessage(baseSepoliaFork);
    console.log("Base Sepolia - After Transfer from Eth Alice Balance:", mockERC20TokenBaseSepolia.balanceOf(aliceBase));
    assertEq(mockERC20TokenBaseSepolia.balanceOf(aliceBase), amountToSend);

    // Eth -> Optimism
    bytes32 messageIdOpt = sendTokens(
        ethSepoliaFork,
        aliceEth,
        ethSepoliaNetworkDetails.routerAddress,
        address(mockERC20TokenEthSepolia),
        address(0),
        optimismSepoliaNetworkDetails.chainSelector,
        aliceOptimism,
        amountToSend
    );
    console.log("Optimism Transfer Message ID (Eth -> Optimism):", uint256(messageIdOpt));
    console.log("Eth Sepolia - After Optimism Transfer Alice Balance:", mockERC20TokenEthSepolia.balanceOf(aliceEth));
    vm.stopPrank();

    assertEq(mockERC20TokenEthSepolia.balanceOf(aliceEth), balanceBeforeEth - amountToSend * 2);
    ccipLocalSimulatorFork.switchChainAndRouteMessage(optimismSepoliaFork);
    console.log("Optimism Sepolia - After Transfer from Eth Alice Balance:", mockERC20TokenOptimismSepolia.balanceOf(aliceOptimism));
    assertEq(mockERC20TokenOptimismSepolia.balanceOf(aliceOptimism), amountToSend);

    // Eth -> Arbitrum
    bytes32 messageIdArb = sendTokens(
        ethSepoliaFork,
        aliceEth,
        ethSepoliaNetworkDetails.routerAddress,
        address(mockERC20TokenEthSepolia),
        address(0),
        arbitrumSepoliaDetails.chainSelector,
        aliceArbitrum,
        amountToSend
    );
    console.log("Arbitrum Transfer Message ID (Eth -> Arbitrum):", uint256(messageIdArb));
    console.log("Eth Sepolia - After Arbitrum Transfer Alice Balance:", mockERC20TokenEthSepolia.balanceOf(aliceEth));
    vm.stopPrank();

    assertEq(mockERC20TokenEthSepolia.balanceOf(aliceEth), balanceBeforeEth - amountToSend * 3);
    ccipLocalSimulatorFork.switchChainAndRouteMessage(arbitrumSepoliaFork);
    console.log("Arbitrum Sepolia - After Transfer from Eth Alice Balance:", mockERC20TokenArbitrumSepolia.balanceOf(aliceArbitrum));
    assertEq(mockERC20TokenArbitrumSepolia.balanceOf(aliceArbitrum), amountToSend);

    // Step 18: Send tokens from Optimism Sepolia back to Eth Sepolia
    vm.selectFork(optimismSepoliaFork);
    vm.startPrank(aliceOptimism);
    ccipLocalSimulatorFork.requestLinkFromFaucet(aliceOptimism, 20 ether); // Request LINK for Optimism
    uint256 balanceBeforeOpt = mockERC20TokenOptimismSepolia.balanceOf(aliceOptimism);

    bytes32 messageIdOptToEth = sendTokens(
        optimismSepoliaFork,
        aliceOptimism,
        optimismSepoliaNetworkDetails.routerAddress,
        address(mockERC20TokenOptimismSepolia),
        address(0),
        ethSepoliaNetworkDetails.chainSelector,
        aliceEth,
        amountToSend
    );
    console.log("Optimism to Eth Transfer Message ID:", uint256(messageIdOptToEth));
    console.log("Optimism Sepolia - After Transfer to Eth Alice Balance:", mockERC20TokenOptimismSepolia.balanceOf(aliceOptimism));
    vm.startPrank(aliceOptimism);
    ccipLocalSimulatorFork.switchChainAndRouteMessage(ethSepoliaFork);
    vm.selectFork(ethSepoliaFork);
    console.log("Eth Sepolia - After Transfer from Optimism Alice Balance:", mockERC20TokenEthSepolia.balanceOf(aliceEth));
    assertEq(mockERC20TokenEthSepolia.balanceOf(aliceEth), balanceBeforeEth - amountToSend *2 ); // 100 back from Optimism
    vm.selectFork(optimismSepoliaFork);
    assertEq(mockERC20TokenOptimismSepolia.balanceOf(aliceOptimism), 0); // All tokens sent back

    // Step 18: Send tokens from Arbitrum Sepolia back to Eth Sepolia
    vm.selectFork(arbitrumSepoliaFork);
    ccipLocalSimulatorFork.requestLinkFromFaucet(aliceArbitrum, 20 ether); // Request LINK for Optimism
    uint256 balanceBeforeArb = mockERC20TokenArbitrumSepolia.balanceOf(aliceArbitrum);

    bytes32 messageIdArbToEth = sendTokens(
        arbitrumSepoliaFork,
        aliceArbitrum,
        arbitrumSepoliaDetails.routerAddress,
        address(mockERC20TokenArbitrumSepolia),
        address(0),
        ethSepoliaNetworkDetails.chainSelector,
        aliceEth,
        amountToSend
    );
    console.log("Arbitrum to Eth Transfer Message ID:", uint256(messageIdArbToEth));
    console.log("Arbitrum Sepolia - After Transfer to Eth Alice Balance:", mockERC20TokenArbitrumSepolia.balanceOf(aliceArbitrum));

    ccipLocalSimulatorFork.switchChainAndRouteMessage(ethSepoliaFork);
    vm.selectFork(ethSepoliaFork);
    console.log("Eth Sepolia - After Transfer from Arbitrum Alice Balance:", mockERC20TokenEthSepolia.balanceOf(aliceEth));
    assertEq(mockERC20TokenEthSepolia.balanceOf(aliceEth), balanceBeforeEth - amountToSend); // 100 back from Optimism
    vm.selectFork(arbitrumSepoliaFork);
    assertEq(mockERC20TokenArbitrumSepolia.balanceOf(aliceOptimism), 0); // All tokens sent back


    // Step 19: Send tokens from Base Sepolia back to Eth Sepolia with debug
    vm.selectFork(baseSepoliaFork);
    ccipLocalSimulatorFork.requestLinkFromFaucet(aliceBase, 20 ether);
    uint256 balanceBeforeBase = mockERC20TokenBaseSepolia.balanceOf(aliceBase);
    console.log("Base Sepolia Pool Address:", address(burnMintTokenPoolBaseSepolia));
    console.log("Base Sepolia Token Address:", address(mockERC20TokenBaseSepolia));
    console.log("Base Sepolia Router Address:", baseSepoliaNetworkDetails.routerAddress);

    // Verify pool configuration
    IERC20 poolToken = IPoolPriorTo1_5(address(burnMintTokenPoolBaseSepolia)).getToken();
    console.log("Base Sepolia Pool Token (should match token address):", address(poolToken));


    bytes32 messageIdBaseToEth = sendTokens(
        baseSepoliaFork,
        aliceBase,
        baseSepoliaNetworkDetails.routerAddress,
        address(mockERC20TokenBaseSepolia),
        address(0),
        ethSepoliaNetworkDetails.chainSelector,
        aliceEth,
        amountToSend
    );
    console.log("Base to Eth Transfer Message ID:", uint256(messageIdBaseToEth));
    console.log("Base Sepolia - After Transfer to Eth Alice Balance:", mockERC20TokenBaseSepolia.balanceOf(aliceBase));

    // Debug before routing
    vm.selectFork(ethSepoliaFork);
    console.log("Eth Sepolia - Before Routing from Base, Alice Balance:", mockERC20TokenEthSepolia.balanceOf(aliceEth));

    ccipLocalSimulatorFork.switchChainAndRouteMessage(ethSepoliaFork);

    vm.selectFork(ethSepoliaFork);
    console.log("Eth Sepolia - After Transfer from Base Alice Balance:", mockERC20TokenEthSepolia.balanceOf(aliceEth));
    vm.selectFork(baseSepoliaFork);
    assertEq(mockERC20TokenBaseSepolia.balanceOf(aliceBase), 0);
    vm.selectFork(ethSepoliaFork);
    assertEq(mockERC20TokenEthSepolia.balanceOf(aliceEth), balanceBeforeEth);
}

// Helper: Deploy a BurnMintTokenPool
function deployTokenPool(
    uint256 fork,
    address deployer,
    address token,
    address rmnProxy,
    address router
) internal returns (BurnMintTokenPool) {
    vm.selectFork(fork);
    vm.startPrank(deployer);
    address[] memory allowlist = new address[](0);
    BurnMintTokenPool pool = new BurnMintTokenPool(
        IBurnMintERC20(token),
        18, // localTokenDecimals
        allowlist,
        rmnProxy,
        router
    );
    console.log("Deployed Pool on Fork", fork, ":", address(pool));
    console.log("Token on Fork", fork, ":", token);
    return pool;
}
// Helper: Grant MINTER and BURNER roles
function grantRoles(uint256 fork, address deployer, address token, address pool) internal {
    vm.selectFork(fork);
    vm.startPrank(deployer);
    phoneToken(token).grantRole(
        phoneToken(token).MINTER_ROLE(),
        pool
    );
    phoneToken(token).grantRole(
        phoneToken(token).BURNER_ROLE(),
        pool
    );
    console.log("Chain", fork, "Minter Role Granted to Pool:", pool);
    vm.stopPrank();
}

// Helper: Register and accept admin role, then set pool
function setupAdminAndPool(
    uint256 fork,
    address deployer,
    address token,
    address pool,
    address registryModuleOwnerCustom,
    address tokenAdminRegistry
) internal {
    vm.selectFork(fork);
    vm.startPrank(deployer);
    RegistryModuleOwnerCustom(registryModuleOwnerCustom).registerAdminViaGetCCIPAdmin(token);
    TokenAdminRegistry(tokenAdminRegistry).acceptAdminRole(token);
    TokenAdminRegistry(tokenAdminRegistry).setPool(token, pool);
    vm.stopPrank();
}


// Helper: Configure a pool with chain updates
function configurePool(
    uint256 fork,
    address deployer,
    address pool,
    uint64[] memory remoteChainSelectors,
    address[] memory remotePools,
    address[] memory remoteTokens
) internal {
    vm.selectFork(fork);
    vm.startPrank(deployer);
    TokenPool.ChainUpdate[] memory chains = new TokenPool.ChainUpdate[](remoteChainSelectors.length);

    for (uint256 i = 0; i < remoteChainSelectors.length; i++) {
        bytes[] memory remotePoolAddresses = new bytes[](1); // Create new array per iteration
        remotePoolAddresses[0] = abi.encode(remotePools[i]);
        chains[i] = TokenPool.ChainUpdate({
            remoteChainSelector: remoteChainSelectors[i],
            remotePoolAddresses: remotePoolAddresses,
            remoteTokenAddress: abi.encode(remoteTokens[i]),
            outboundRateLimiterConfig: RateLimiter.Config({ isEnabled: true, capacity: 100_000, rate: 167 }),
            inboundRateLimiterConfig: RateLimiter.Config({ isEnabled: true, capacity: 100_000, rate: 167 })
        });
    }

    BurnMintTokenPool(pool).applyChainUpdates(new uint64[](0), chains);
    vm.stopPrank();
}
// Helper: Send tokens via CCIP
function sendTokens(
    uint256 fork,
    address sender,
    address router,
    address token,
    address link, // Kept for compatibility, but ignored for ETH fees
    uint64 remoteChainSelector,
    address receiver,
    uint256 amount
) internal returns (bytes32) {
    vm.selectFork(fork);
    vm.startPrank(sender);

    // Approve the router to spend the token being transferred
    MockERC20BurnAndMintToken(token).approve(router, amount);

    // Prepare the CCIP message
    Client.EVMTokenAmount[] memory tokenToSendDetails = new Client.EVMTokenAmount[](1);
    tokenToSendDetails[0] = Client.EVMTokenAmount({ token: token, amount: amount });
    Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
        receiver: abi.encode(receiver),
        data: "",
        tokenAmounts: tokenToSendDetails,
        extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({ gasLimit: 0 })),
        feeToken: address(0) // Use native ETH for fees
    });

    // Calculate the fee in ETH
    uint256 fees = IRouterClient(router).getFee(remoteChainSelector, message);
    
    // Ensure sender has enough ETH (for testing purposes, vm.deal could be used outside this function)
    require(address(sender).balance >= fees, "Insufficient ETH for fees");

    // Send the CCIP message with ETH fees
    bytes32 messageId = IRouterClient(router).ccipSend{value: fees}(
        remoteChainSelector,
        message
    );

    vm.stopPrank();
    return messageId;
}
}