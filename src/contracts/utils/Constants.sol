// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;
pragma abicoder v2;

library Constants {
    // Sepolia AggregatorV3Interface to access price from chainlink
    address internal constant ETH_USD = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address internal constant GHO_USD = 0x635A86F9fdD16Ff09A0701C305D3a845F1758b8E;

    // Mainnet addresses
    address internal constant GHO = 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant RETH = 0xae78736Cd615f374D3085123A210448E74Fc6393;

    // Uniswap swap router
    address internal constant SWAP_ROUTER =0xE592427A0AEce92De3Edee1F18E0157C05861564;

    uint256 internal constant POOL_FEE = 3000;
    bytes internal constant BUY_WETH_PATH = abi.encodePacked(GHO, POOL_FEE, USDC, POOL_FEE, WETH9);
    bytes internal constant SELL_WETH_PATH = abi.encodePacked(WETH9, POOL_FEE, USDC, POOL_FEE, GHO);
    bytes internal constant BUY_RETH_PATH = abi.encodePacked(GHO, POOL_FEE, USDC, POOL_FEE, WETH9, POOL_FEE, RETH);
    bytes internal constant SELL_RETH_PATH = abi.encodePacked(RETH, POOL_FEE, WETH9, POOL_FEE, USDC, POOL_FEE, GHO);
}