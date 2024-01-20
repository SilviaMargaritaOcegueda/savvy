// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IWETH9} from "./IWETH9.sol";

contract GhoInteraction {
    // TODO eleminate if not used
    IERC20 dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    // USDC, DAI, USDT

    // Sepolia IPool pool = IPool(0x617Cf26407193E32a771264fB5e9b8f09715CdfB);
    IPool pool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
    // Sepolia IERC20 gho = IERC20(0xcbE9771eD31e761b744D3cB9eF78A1f32DD99211);
    IERC20 gho = IERC20(0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f);
    IWETH9 WETH9 = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    
    error InsufficientETH();
    
    // functions to get GHO-Token: 
    // 1. approveEth
    // 2. supplyLiquidity
    // 3. borrowGho
    function approveETH(IERC20 _ierc20, uint256 _amount)
        external
        returns (bool)
    {
        // TODO Call with eth.approve
        return _ierc20.approve(address(pool), _amount);
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


    
    /// Wraps an amount of ETH into WETH
    function wrapETH(uint256 amount) internal {
            WETH9.deposit{value: amount}();
    }

    /// Unwraps contract's WETH into ETH
    /// True for unwrap amount, and false for unwrap all the contract balance 
    function unwrapWETH9(uint256 amount, bool unwrapAmount) internal {
        uint256 value = WETH9.balanceOf(address(this));
        if (value < amount) {
            revert InsufficientETH();
        }
        if (unwrapAmount) {
            WETH9.withdraw(amount);
        } else {
            WETH9.withdraw(value);
        }
    }
}