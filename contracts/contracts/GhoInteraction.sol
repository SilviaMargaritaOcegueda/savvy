// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";

contract GhoInteraction {
    // TODO eleminate if not used
    IERC20 dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    // USDC, DAI, USDT

    // Sepolia IPool pool = IPool(0x617Cf26407193E32a771264fB5e9b8f09715CdfB);
    IPool pool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
    // Sepolia IERC20 gho = IERC20(0xcbE9771eD31e761b744D3cB9eF78A1f32DD99211);
    IERC20 gho = IERC20(0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f);
    
    
    // functions to get GHO-Token: 
    // 1. approveEth
    // 2. supplyLiquidity
    // 3. borrowGho
    function approveETH(uint256 _amount)
        external
        returns (bool)
    {
        // TODO Call with eth.approve
        return dai.approve(address(pool), _amount);
    }

    function supplyLiquidity(address asset, uint256 amount, address onBehalfOf) 
        internal 
    {
        pool.supply(asset, amount, onBehalfOf, 0);
    }

    function borrowGho(address asset, uint256 amount, address onBehalfOf) 
        internal 
    {    
        pool.borrow(asset, amount, 1, 0, onBehalfOf);
    }

    // function to withdrwa GHO
    function withdrawGho(address asset, uint256 amount, address to) 
        external returns (uint256) {
            uint withdrawAmount = pool.withdraw(asset, amount, to);
            return withdrawAmount;
        }
}

    WETH9 = IWETH9(params.weth9)
    
    /// @notice Wraps an amount of ETH into WETH
    /// @param recipient The recipient of the WETH
    /// @param amount The amount to wrap (can be CONTRACT_BALANCE)
    function wrapETH(address recipient, uint256 amount) internal {
        if (amount == Constants.CONTRACT_BALANCE) {
            amount = address(this).balance;
        } else if (amount > address(this).balance) {
            revert InsufficientETH();
        }
        if (amount > 0) {
            WETH9.deposit{value: amount}();
            if (recipient != address(this)) {
                WETH9.transfer(recipient, amount);
            }
        }
    }

    /// @notice Unwraps all of the contract's WETH into ETH
    /// @param recipient The recipient of the ETH
    /// @param amountMinimum The minimum amount of ETH desired
    function unwrapWETH9(address recipient, uint256 amountMinimum) internal {
        uint256 value = WETH9.balanceOf(address(this));
        if (value < amountMinimum) {
            revert InsufficientETH();
        }
        if (value > 0) {
            WETH9.withdraw(value);
            if (recipient != address(this)) {
                recipient.safeTransferETH(value);
            }
        }
    }