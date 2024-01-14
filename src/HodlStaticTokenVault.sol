// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract HodlStaticTokenVault {

    address STRATEGY_ASSET = ETH;
    address UNDERLYING_ASSET = GHO_TOKEN;
    uint256 LAST_PURCHASE;
    uint256 lastAveragePrice;
    bool claimEnabled = false;
    bool setModeEnabled = false;
    bool strategyExited = false;
    StrategyOption strategyOption;

    // Custom error for non-student callers
    error NotAStudent();

    // Mapping to associate each strategy option with its parameters
    mapping(StrategyOption => StrategyParams) public strategyParams;

    uint256[] prices;
    mapping(uint2556 price => amountOfStrategyAsset) public purchasePrices;

    // TODO when student supplies liquidity check his status to either add the balance 
    // to liquidityToInvest or to saveOnlyTotal  
    address[] students;
    mapping(address student => StudentMode) public studentsMode;

    uint256 liquidityToInvest;
    uint256 saveOnlyTotal;
    uint256 underlyingAssetOnProfitTotal;

    // Modifier to check if the message sender is a student
    modifier onlyStudents() {
        if (!_isStudent(msg.sender)) {
            revert NotAStudent();
        }
        _;
    }

    // constructor
    constructor(
        _strategyOption,
        weeklyAmount,
        timestamp lastDeposit,
        uint256 firstPurchaseTimestamp,
        address underlyingAsset,
        address schoolAddress,
        address owner

    ) {
        // TODO calculate last purchase
        LAST_PURCHASE = firstPurchaseTimestamp;
        strategyOption = _strategyOption;
    }

    // only owner functions
    function addStudents(address[] calldata newStudents) public onlyOwner {
        for (uint i = 0; i < newStudents.length; i++) {
            students.push(newStudents[i]);
        }
    }

    function restartStrategy(StrategyOption newStrategy) public onlyOwner {
        _updateLiquidityToInvest();
        (uint256 amount, uint256 price) = _buyStrategyAsset(liquidityToInvest);
        _clearPurchasePrices();
        purchasePrices[price] += amount;
        lastAveragePrice = _getAveragePrice();
        _setStrategyParams();
        strategyExited = false; 
    }
    
    function emergencyExit() public onlyOwner {
        _sellStrategyAsset(this.balance, 100);
        _enableClaim();
        strategyExited = true;
    }

    // automated actions
    function purchaseWeekly() private {
        // TODO implement automation every week after firstPurchase until LAST_PURCHASE
        require(!strategyExited);
        (uint256 amount, uint256 price) = _buyStrategyAsset(liquidityToInvest);
        purchasePrices[price] += amount;
        lastAveragePrice = _getAveragePrice();
    }

    function takeProfit() private {
        // TODO implement automation with a daily basis
        require(!strategyExited);
        if (strategyAssetPrice >= averagePrice.plus(strategyParams[strategyOption].targetPrice3.priceIncreasePercentage)) {
            underlyingAssetOnProfitTotal += _sellStrategyAsset(this.balance, (strategyParams[strategyOption].targetPrice3.sellPercentage));
        } else if (strategyAssetPrice >= averagePrice.plus(strategyParams[strategyOption].targetPrice2.priceIncreasePercentage)) {
            underlyingAssetOnProfitTotal += _sellStrategyAsset(this.balance, (strategyParams[strategyOption].targetPrice2.sellPercentage));
        } else if (strategyAssetPrice >= averagePrice.plus(strategyParams[strategyOption].targetPrice1.priceIncreasePercentage)) {
            underlyingAssetOnProfitTotal += _sellStrategyAsset(this.balance, (strategyParams[strategyOption].targetPrice1.sellPercentage));
        }
    }

    function stopLoss() private {
        // TODO implement automation at the lastAveragePrice 
        // lastAveragePrice gets updated every time purchaseWeekly() is triggered
        require(!strategyExited);
        _sellStrategyAsset(this.balance, uint256(100));
        setModeEnabled = true;
    }

    // Students functions
    function setStudentMode(StudentMode newMode) public onlyStudent {
        studentsMode[msg.sender] = newMode;
        if (newMode == SAVE_ONLY) {
            // TODO use the  ERC function to get a user underlying asset balance
            saveOnlyTotal += getStudentUnderlyingAssetBalance();
        }
    }

    function _sellStrategyAsset(uint256 total, uint256 percentageToSell) private returns (uint256 receivedAmount) {
        uint256 amountToSwitch = _calculateAbsoluteAmountfromPercentage(total, percentageToSell);
        ( , receivedAmount) = _switchAssets(STRATEGY_ASSET, UNDERLYING_ASSET, amountToSwitch);
        return receivedAmount;
    }

    function _buyStrategyAsset(uint256 liquidityToInvest) private returns (uint256 price, uint256 receivedAmount) {
        return _switchAssets(UNDERLYING_ASSET, STRATEGY_ASSET, liquidityToInvest);
    }

    function _switchAssets(address assetOut, address assetIn, uint amountofAssetOut) private returns (uint price, uint256 receivedAmount) {
        // TODO declare and implement function
        return aave.switchTokens();
    };

    // Helper functions
    function _enableClaim() private {
        claimEnabled = true;
    }

    function _disableClaim() private {
        claimEnabled = false;
    }

    // Function to check if an address is a student
    function _isStudent(address _address) private view returns(bool) {
        for (uint i = 0; i < students.length; i++) {
            if (students[i] == _address) {
                return true;
            }
        }
        return false;
    }

    // TODO Implement these functions
    function _calculateAbsoluteAmountfromPercentage(uint256 total, uint256 percentageToSell);
    function _getAveragePrice() public pure {}
    
    // Set the strategyParams for each strategy option
    function _setStrategyParams() private {
        strategyParams[StrategyOption.CONSERVATIVE] = StrategyParams({
            targetPrice1: TargetPriceParams({sellPercentage: 5, priceIncreasePercentage: 10}), 
            targetPrice2: TargetPriceParams({sellPercentage: 10, priceIncreasePercentage: 20}), 
            targetPrice3: TargetPriceParams({sellPercentage: 15, priceIncreasePercentage: 30}), 
            priceDecreasePercentage: 10});
        strategyParams[StrategyOption.MODERATE] = StrategyParams({
            targetPrice1: TargetPriceParams({sellPercentage: 10, priceIncreasePercentage: 15}), 
            targetPrice2: TargetPriceParams({sellPercentage: 15, priceIncreasePercentage: 25}), 
            targetPrice3: TargetPriceParams({sellPercentage: 20, priceIncreasePercentage: 35}), 
            priceDecreasePercentage: 15});
        strategyParams[StrategyOption.AGGRESSIVE] = StrategyParams({
            targetPrice1: TargetPriceParams({sellPercentage: 15, priceIncreasePercentage: 20}), 
            targetPrice2: TargetPriceParams({sellPercentage: 20, priceIncreasePercentage: 30}), 
            targetPrice3: TargetPriceParams({sellPercentage: 25, priceIncreasePercentage: 40}), 
            priceDecreasePercentage: 20});
    }
}

