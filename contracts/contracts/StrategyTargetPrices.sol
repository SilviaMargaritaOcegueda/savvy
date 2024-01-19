// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma abicoder v2;

import "./utils/DataTypes.sol";
import "./Swapper.sol";
import "./utils/Constants.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract StrategyTargetPrices is Swapper {
    address immutable underlyingAsset;
    address public immutable strategyAsset;
    bool public isStrategyExited = false;
    bool public isSetModeEnabled = false;
    bool public isStrategyStopped = false;
    uint256 public lastAveragePrice;
    uint256 underlyingAssetOnProfitTotal;
    uint24 public constant poolFee = 3000;

    // To access strategy asset price from chainlink
    AggregatorV3Interface internal dataFeed; 
    
    // Associates each strategy option with its parameters
    mapping(DataTypes.StrategyOption => DataTypes.StrategyParams) public strategyParams;

    event ProfitTaken(
        uint256 tier, 
        uint256 price, 
        uint256 soldAmount
    );
    
    event LossStopped(
        uint256 price,
        uint256 receivedAmount
    );

    constructor(
        address _aggregator, 
        address _swapRouter,
        address _underlyingAsset,
        address _strategyAsset
    ) Swapper(ISwapRouter(_swapRouter)) {
        dataFeed = AggregatorV3Interface(_aggregator);
        underlyingAsset = _underlyingAsset;
        strategyAsset = _strategyAsset;
    }

    // In this contract, we represent percentages as basis points (bps) where 1% = 100 bps.
    function _setStrategyParams() private {
        strategyParams[DataTypes.StrategyOption.CONSERVATIVE] = DataTypes.StrategyParams({
            targetPrice1: DataTypes.TargetPriceParams({sellBasisPoints: 500, priceIncreaseBasisPoints: 1000}), 
            targetPrice2: DataTypes.TargetPriceParams({sellBasisPoints: 1000, priceIncreaseBasisPoints: 2000}), 
            targetPrice3: DataTypes.TargetPriceParams({sellBasisPoints: 1500, priceIncreaseBasisPoints: 3000}), 
            priceDecreaseBasisPoints: 1000});
        strategyParams[DataTypes.StrategyOption.MODERATE] = DataTypes.StrategyParams({
            targetPrice1: DataTypes.TargetPriceParams({sellBasisPoints: 1000, priceIncreaseBasisPoints: 1500}), 
            targetPrice2: DataTypes.TargetPriceParams({sellBasisPoints: 1500, priceIncreaseBasisPoints: 2500}), 
            targetPrice3: DataTypes.TargetPriceParams({sellBasisPoints: 2000, priceIncreaseBasisPoints: 3500}), 
            priceDecreaseBasisPoints: 1500});
        strategyParams[DataTypes.StrategyOption.AGGRESSIVE] = DataTypes.StrategyParams({
            targetPrice1: DataTypes.TargetPriceParams({sellBasisPoints: 1500, priceIncreaseBasisPoints: 2000}), 
            targetPrice2: DataTypes.TargetPriceParams({sellBasisPoints: 2000, priceIncreaseBasisPoints: 3000}), 
            targetPrice3: DataTypes.TargetPriceParams({sellBasisPoints: 2500, priceIncreaseBasisPoints: 4000}), 
            priceDecreaseBasisPoints: 2000});
    }

    function takeProfit(DataTypes.StrategyOption _strategyOption) internal {
        require(!isStrategyExited, "Strategy exited");
        (uint256 targetPrice3, uint256 targetPrice2, uint256 targetPrice1) = getTargetPrices(_strategyOption);
        require((targetPrice3 - lastAveragePrice) >= 10_000, "Price increment rounds to zero");
        if (getOraclePrice() >= targetPrice3) {
             (uint256 price, uint256 receivedAmount) = sellStrategyAsset(address(this).balance, strategyParams[_strategyOption].targetPrice3.sellBasisPoints);
             underlyingAssetOnProfitTotal += receivedAmount;
            emit ProfitTaken(3, price, receivedAmount);
        } else if (getOraclePrice() >= targetPrice2) {
            (uint256 price, uint256 receivedAmount) = sellStrategyAsset(address(this).balance, strategyParams[_strategyOption].targetPrice2.sellBasisPoints);
            underlyingAssetOnProfitTotal += receivedAmount;
            emit ProfitTaken(2, price, receivedAmount);
        } else if (getOraclePrice() >= targetPrice1) {
            (uint256 price, uint256 receivedAmount) = sellStrategyAsset(address(this).balance, strategyParams[_strategyOption].targetPrice1.sellBasisPoints);
            underlyingAssetOnProfitTotal += receivedAmount;
            emit ProfitTaken(1, price, receivedAmount);
        }
    }

    function getTargetPrices(DataTypes.StrategyOption _strategyOption) internal view returns (uint256, uint256, uint256) {
        uint256 targetPrice3 = lastAveragePrice + 
            (lastAveragePrice * (strategyParams[_strategyOption].targetPrice3.priceIncreaseBasisPoints) / 10_000);
        uint256 targetPrice2 = lastAveragePrice + 
            (lastAveragePrice * (strategyParams[_strategyOption].targetPrice2.priceIncreaseBasisPoints) / 10_000);
        uint256 targetPrice1 = lastAveragePrice + 
            (lastAveragePrice * (strategyParams[_strategyOption].targetPrice1.priceIncreaseBasisPoints) / 10_000);
        
        return (targetPrice3, targetPrice2, targetPrice1);
    }

    function getOraclePrice() internal view returns(uint256) {
        (
            /* uint80 roundID */,
            int256 answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return uint256(answer);
    }

    function sellStrategyAsset(uint256 total, uint256 bpsToSell) internal returns (uint256 price, uint256 receivedAmount) {
        uint256 amountToSwap = _calculateAmountfromBasisPoints(total, bpsToSell);
        bytes memory path = abi.encodePacked(underlyingAsset, poolFee, AddressBook.USDC, poolFee, strategyAsset);
        return swapExactInputMultihop(strategyAsset, amountToSwap, path);
    }

    function _calculateAmountfromBasisPoints(uint256 total, uint256 bpsToSell) private pure returns (uint256) {
        require((total * bpsToSell) >= 10_000);
        return total * bpsToSell / 10_000;
    }

    function _getStopPrice(DataTypes.StrategyOption _strategyOption) private view returns (uint256) {
       return lastAveragePrice + 
            (lastAveragePrice * (strategyParams[_strategyOption].priceDecreaseBasisPoints) / 10_000);
    }

    function stopLoss() internal {
        require(!isStrategyExited);
        (uint256 price, uint256 receivedAmount) = sellStrategyAsset(address(this).balance, 10_000);
        isSetModeEnabled = true;
        isStrategyStopped = true;
        emit LossStopped(price, receivedAmount);
    }
}