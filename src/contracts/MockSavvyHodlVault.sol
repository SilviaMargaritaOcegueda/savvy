// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2;
import "./SavvyHodlVault.sol";

contract MockSavvyHodlVault is SavvyHodlVault {

    constructor(
        address _underlyingAsset, // in constants
        address _strategyAsset, // in constants
        address _swapRouter, // in constants
        address _aggregator, // in constants
        string memory _strategyName, // frontend i.e. hodl_ETH rETH_liqStaking
        uint256 _weeklyAmount, // frontend
        uint256 _initialDepositTimestamp, // frontend
        uint256 _finalDepositTimestamp, // frontend
        address _classAddress, // frontend
        address _teacherAddress, // frontend
        address[] memory _students // frontend
    ) public 
    SavvyHodlVault(
            StrategyBallot(_teacherAddress), 
            ERC4626(IERC20(_underlyingAsset)) 
            ERC20('savvyGHO', 'sGHO') 
            StrategyTargetPrices(_aggregator, _swapRouter, _underlyingAsset, _strategyAsset)
        )
        {
        strategyName = _strategyName;
        firstPurchaseTimestamp = _initialDepositTimestamp + 1 days;
        finalPurchaseTimestamp = _finalDepositTimestamp + 1 days;
        lastTimeStampAutomation = finalPurchaseTimestamp + 1 days;
        finalWithdrawalTimestamp = lastTimeStampAutomation + 90 days;
        students = _students;
        classAddress = payable(_classAddress);
        weeklyAmount = _weeklyAmount;
    }

    // has to be set that stoploos or takeprofit will be triggered
    function getAveragePrice(uint256 _value) public virtual override view returns (uint256){
        return _value;
    }

    // has to be set higher than targetPrice to trigger takeprofit
    // has to be set smaller than exitprice (based on average price) to trigger stoploss
    function getOraclePrice(uint256 _value) public virtual override view returns (uint256){
        return _value;
    }

    function setLastTimestampAutomation(uint256 _timeStamp) public {
        lastTimeStampAutomation = _timeStamp;
    } 
}