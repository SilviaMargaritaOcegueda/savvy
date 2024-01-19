// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

//import "https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/ISwapRouter.sol";
//import "https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol";
// staking path > abi.encodePacked(GHO, poolFee, USDC, poolFee, WETH9, poolFee, RETH)
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import "./utils/AddressBook.sol";

contract Swapper {
    ISwapRouter public immutable swapRouter;

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }

    function swapExactInputMultihop(address assetIn, uint256 amountIn,  bytes memory _path) internal returns (uint256 price, uint256 amountOut) {
        // Transfer `amountIn` of assetIn to this contract.
        TransferHelper.safeTransferFrom(assetIn, msg.sender, address(this), amountIn);

        // Approve the router to spend assetIn.
        TransferHelper.safeApprove(assetIn, address(swapRouter), amountIn);

        // Multiple pool swaps are encoded through bytes called a `path`. A path is a sequence of token addresses and poolFees that define the pools used in the swaps.
        // The format for pool encoding is (tokenIn, fee, tokenOut/tokenIn, fee, tokenOut) where tokenIn/tokenOut parameter is the shared token across the pools.
        // Since we are swapping DAI to USDC and then USDC to WETH9 the path encoding is (DAI, 0.3%, USDC, 0.3%, WETH9).
        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: _path,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0
            });

        // Executes the swap
        amountOut = swapRouter.exactInput(params);
        price = _getStrategyAssetPurchasePrice(amountOut, amountIn);
        
        return (price, amountOut);
    }

    function _getStrategyAssetPurchasePrice(
        uint256 _purchasedStrategyAssetAmount, 
        uint256 _paidGHOAmount
    ) private pure returns (uint256) {
    require(_purchasedStrategyAssetAmount > 0 && _paidGHOAmount > 0, "Amounts must be greater than zero");

    // Calculate the price of 1 strategy asset token in USD stablecoin
    // Price (in USD stablecoin) = Paid amount (in USD stablecoin) / Purchased amount (in StrategyAsset)
    return (_paidGHOAmount * (10**18)) / _purchasedStrategyAssetAmount;
    }
}