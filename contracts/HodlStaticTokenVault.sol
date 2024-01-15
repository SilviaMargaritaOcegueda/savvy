// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./DataTypes.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// Sepolia 
// ETH / USD 0x694AA1769357215DE4FAC081bf1f309aDC325306
// GHO / USD 0x635A86F9fdD16Ff09A0701C305D3a845F1758b8E
// chainlink automation 
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract HodlStaticTokenVault is AutomationCompatibleInterface {
    AggregatorV3Interface internal dataFeed;

    address public immutable strategyAsset;
    address public immutable underlyingAsset;
    address payable public classAddress;
    uint256 public immutable firstPurchaseTimestamp;
    uint256 public immutable finalPurchaseTimestamp;
    uint256 public immutable destructionTimestamp;
    uint256 public lastAveragePrice;
    uint256 public weeklyAmount;
    uint256 liquidityToInvest;
    uint256 saveOnlyTotal;
    uint256 underlyingAssetOnProfitTotal;
    bool public isClaimEnabled = false;
    bool public isSetModeEnabled = false;
    bool public isStrategyExited = false;
    bool public isStrategyStopped = false;
    StrategyOption public strategyOption;



    // Use an interval in seconds and a timestamp to slow execution of Upkeep
    uint256 public immutable intervalAutomation;
    uint256 public lastTimeStampAutomation;

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
        StrategyOption _strategyOption,
        uint256 _weeklyAmount,
        uint256 _initialDepositTimestamp,
        uint256 _finalDepositTimestamp,
        address _strategyAsset,
        address _underlyingAsset,
        address _classAddress,
        address _owner, // teacher address
        uint256 _updateInterval,
        address[] calldata _newStudents
    ) {
        firstPurchaseTimestamp = _initialDepositTimestamp + (1 days);
        finalPurchaseTimestamp = _finalDepositTimestamp + (1 days);
        strategyAsset = _strategyAsset;
        underlyingAsset = _underlyingAsset;
        _addStudents(_newStudents);
        strategyOption = _strategyOption;
        classAddress = _classAddress;
        weeklyAmount = _weeklyAmount;
        // to access Eth price from chainlink
        dataFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        // set everything for automation
        intervalAutomation = _updateInterval;
        lastTimeStampAutomation = block.timestamp;
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
    
    /// @dev Sells remaining holdings and enables claims
    function emergencyExit() public onlyOwner {
        _sellStrategyAsset(address(this).balance, 100);
        _enableClaim();
        isStrategyExited = true;
    }

    /// @dev Destroys the vault and send any remaining balance to class address 
    function destroyContract() public onlyOwner {
        require(block.timestamp >= destructionTimestamp, "Too early to destroy");
        selfdestruct(classAddress);
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
        ( , receivedAmount) = _switchAssets(strategyAsset, underlyingAsset, amountToSwitch);
        return receivedAmount;
    }

    function _buyStrategyAsset(uint256 liquidityToInvest) private returns (uint256 price, uint256 receivedAmount) {
        return _switchAssets(underlyingAsset, strategyAsset, liquidityToInvest);
    }

    function _switchAssets(address assetOut, address assetIn, uint amountofAssetOut) private returns (uint price, uint256 receivedAmount) {
        // TODO declare and implement function
        return aave.switchTokens();
    }

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

    function _calculateAbsoluteAmountfromPercentage(uint256 total, uint256 percentageToSell) private pure returns (uint256) {
        return (total * percentageToSell) / 100; // Rounds down to the nearest integer
    }
    
    function _getAveragePrice() internal view returns (uint256) {
        uint256 totalValue = 0;
        uint256 totalAmount = 0;

        for (uint256 i = 0; i < prices.length; i++) {
            totalValue += prices[i] * uint256(purchasePrices[prices[i]]);
            totalAmount += uint256(purchasePrices[prices[i]]);
        }
        if (totalAmount == 0) {
            return 0;
        }
        return totalValue / totalAmount;  // Rounds down to the nearest integer
    }
    
    // function _getAverage() public view returns (int) {
    //     // how shall it be calculated? always a week window?
    //     (
    //         /* uint80 roundID */,
    //         int answer,
    //         /*uint startedAt*/,
    //         /*uint timeStamp*/,
    //         /*uint80 answeredInRound*/
    //     ) = dataFeed.latestRoundData();
    //     return answer;
    // }
    
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

    // Chainlink function for setting automation based on a timeinterval
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    // Chainlink function to perform automation action
    // we have to call what shall be performed during autamation inside this function
    function performUpkeep(bytes calldata /* performData */) external override {
        if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;
            counter = counter + 1;
        }
        // We don't use the performData in this example. The performData is generated by the Automation Node's call to your checkUpkeep function
    }
}


