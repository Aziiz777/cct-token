// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/MiddleEastE-commerce.sol";
import "@chainlink-ccip/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import "@chainlink-ccip/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract EstimateCCIPFee is Script {
    function run() external {
        address ccipRouter = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59; // Sepolia
        uint64 destinationChainSelector = 13264668187771770619; // BSC Testnet
        address receiver = 0xAE1710C414E95B83c247E01E8F30eE117771599B;
        address tokenAddress = 0x3DC019C8b47E195D169B0FE2BdBeD2548bFcfF44;
        uint256 amount = 1000000000000000000000;

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: "",
            tokenAmounts: new Client.EVMTokenAmount[](1),
            feeToken: address(0),
            extraArgs: abi.encodeWithSelector(
                bytes4(keccak256("CCIP EVMExtraArgsV1")),
                Client.EVMExtraArgsV1({gasLimit: 200_000})
            )
        });

        message.tokenAmounts[0] = Client.EVMTokenAmount({
            token: tokenAddress,
            amount: amount
        });

        IRouterClient router = IRouterClient(ccipRouter);
        uint256 fee = router.getFee(destinationChainSelector, message);

        console.log("Estimated CCIP Fee (wei):", fee);
        console.log("Estimated CCIP Fee (ETH):", fee / 1e18);
    }
}