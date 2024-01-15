// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract HodlStaticTokenVault {

    address public STRATEGY_ASSET;
    address public UNDERLYING_ASSET;
    uint256 public FIRST_PURCHASE_TIMESTAMP;
    uint256 public FINAL_PURCHASE_TIMESTAMP;
    uint256 public lastAveragePrice;
    uint256 liquidityToInvest;
    uint256 saveOnlyTotal;
    uint256 underlyingAssetOnProfitTotal;
    bool public isClaimEnabled = false;
    bool public isSetModeEnabled = false;
    bool public isStrategyExited = false;
    bool public isStrategyStopped = false;
    StrategyOption public strategyOption;

    // Custom error for non-student callers
    error NotAStudent();

    // Mapping to associate each strategy option with its parameters
    mapping(StrategyOption => StrategyParams) public strategyParams;

    uint256[] public prices;
    // Mapping to associate each purchase price with the amount of strategy asset purchased
    mapping(uint256 => amountOfStrategyAsset) public purchasePrices;

    // TODO when student supplies liquidity check his status to either add the balance 
    // to liquidityToInvest or to saveOnlyTotal  
    address[] students;
    // Mapping to associate each student address with their mode
    mapping(address => StudentMode) public studentsMode;  


    // Modifier to check if the message sender is a student
    modifier onlyStudents() {
        if (!_isStudent(msg.sender)) {
            revert NotAStudent();
        }
        _;
    }

    /// @dev Initializes the HodlStaticTokenVault contract with the provided parameters.
    constructor(
        StrategyOption option,
        uint256 weeklyAmount,
        uint256 lastDepositTimestamp,
        uint256 firstPurchaseTimestamp,
        address strategyAsset,
        address underlyingAsset,
        address schoolAddress,
        address owner,
        address[] calldata newStudents
    ) {
        // TODO calculate final purchase timestamp
        FIRST_PURCHASE_TIMESTAMP = firstPurchaseTimestamp;
        FINAL_PURCHASE_TIMESTAMP = firstPurchaseTimestamp;
        STRATEGY_ASSET = strategyAsset;
        UNDERLYING_ASSET = underlyingAsset;
        strategyOption = option;
        _addStudents(newStudents);
    }

    // only owner functions

    /// @dev After a stop loss event, restarts the strategy with the new provided strategy option.
    function restartStrategy(StrategyOption newStrategy) public onlyOwner {
        require(isStrategyStopped);
        _updateLiquidityToInvest();
        _clearPurchasePrices();
        (uint256 amount, uint256 price) = _buyStrategyAsset(liquidityToInvest);
        purchasePrices[price] += amount;
        lastAveragePrice = _getAveragePrice();
        strategyOption = newStrategy;
        isStrategyExited = false; 
    }
    
    /// @dev Sells remaining ETH holdings and enables claims
    function emergencyExit() public onlyOwner {
        _sellStrategyAsset(address(this).balance, 100);
        _enableClaim();
        isStrategyExited = true;
    }

    // Automated actions
    function purchaseWeekly() private {
        require(!isStrategyExited, "Strategy exited");
        (uint256 amount, uint256 price) = _buyStrategyAsset(liquidityToInvest);
        purchasePrices[price] += amount;
        lastAveragePrice = _getAveragePrice();
    }

    function takeProfit() private {
        require(!isStrategyExited, "Strategy exited");
        if (strategyAssetPrice >= lastAveragePrice + strategyParams[strategyOption].targetPrice3.priceIncreasePercentage) {
            underlyingAssetOnProfitTotal += _sellStrategyAsset(address(this).balance, strategyParams[strategyOption].targetPrice3.sellPercentage);
        } else if (strategyAssetPrice >= lastAveragePrice + strategyParams[strategyOption].targetPrice2.priceIncreasePercentage) {
            underlyingAssetOnProfitTotal += _sellStrategyAsset(address(this).balance, strategyParams[strategyOption].targetPrice2.sellPercentage);
        } else if (strategyAssetPrice >= lastAveragePrice + strategyParams[strategyOption].targetPrice1.priceIncreasePercentage) {
            underlyingAssetOnProfitTotal += _sellStrategyAsset(address(this).balance, strategyParams[strategyOption].targetPrice1.sellPercentage);
        }
    }

    function stopLoss() private {
        require(!isStrategyExited);
        _sellStrategyAsset(address(this).balance, uint256(100));
        isSetModeEnabled = true;
        isStrategyStopped = true;
    }

    // Students functions
    /// @dev Sets the mode for the calling student.
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
        isClaimEnabled = true;
    }

    function _disableClaim() private {
        isClaimEnabled = false;
    }

    // Adds the provided students to the list of students.
    function _addStudents(address[] calldata newStudents) private {
        for (uint i = 0; i < newStudents.length; i++) {
            students.push(newStudents[i]);
        }
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
