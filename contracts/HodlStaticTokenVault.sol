// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./DataTypes.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/Denominations.sol";
// Sepolia 
// ETH / USD 0x694AA1769357215DE4FAC081bf1f309aDC325306
// GHO / USD 0x635A86F9fdD16Ff09A0701C305D3a845F1758b8E
// chainlink automation 
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HodlStaticTokenVault is AutomationCompatibleInterface, Ownable {
    using DataTypes for DataTypes.StrategyOption;
    using DataTypes for DataTypes.StrategyParams;
    using DataTypes for DataTypes.StudentMode;

    address public immutable strategyAsset;
    address public immutable underlyingAsset;
    address payable public classAddress;
    uint256 public immutable firstPurchaseTimestamp;
    uint256 public immutable finalPurchaseTimestamp;
    uint256 public immutable destructionTimestamp;
    uint256 public strategyAssetPrice;
    uint256 public lastAveragePrice;
    uint256 public weeklyAmount;
    uint256 liquidityToInvest;
    uint256 saveOnlyTotal;
    uint256 underlyingAssetOnProfitTotal;
    uint256 conservativeVotes;
    uint256 moderateVotes;
    uint256 aggressiveVotes;
    bool public isClaimEnabled = false;
    bool public isSetModeEnabled = false;
    bool public isStrategyExited = false;
    bool public isStrategyStopped = false;
    StrategyOption public strategyOption;

    // to access Eth price from chainlink
    AggregatorV3Interface internal dataFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    // Use an interval in seconds and a timestamp to slow execution of Upkeep
    uint256 public immutable intervalAutomation = uint256(604_800);
    uint256 public lastTimeStampAutomation = finalPurchaseTimestamp + (1 days);

    error NotAStudent();
    error StudentHasVoted();
    error TieVoteAgain();

    // Associates each strategy option with its parameters
    mapping(StrategyOption => StrategyParams) public strategyParams;

    uint256[] public prices;
    // Associates each purchase price with the amount of strategy asset purchased at that price
    mapping(uint256 => uint256) public purchasePrices;

    // TODO when student supplies liquidity check his status to either add the balance 
    // to liquidityToInvest or to saveOnlyTotal  
    address[] students;
    // Associates each student address with their mode
    mapping(address => StudentMode) public studentsMode;  
    // Associate student with a boolean indicating whether the student has already voted
    mapping(address => bool) public studentHasVoted;


    // Modifier to check if the message sender is a student
    modifier onlyStudents() {
        if (!_isStudent(msg.sender)) {
            revert NotAStudent();
        }
        _;
    }

    /// @dev Initializes the HodlStaticTokenVault contract with the provided parameters.
    constructor(
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
        classAddress = _classAddress;
        weeklyAmount = _weeklyAmount;
    }

    // only owner functions

    /// @dev After a stop loss event, restarts the strategy with the new provided strategy option.
    function restartStrategy(StrategyOption newStrategy) public onlyOwner {
        require(isStrategyStopped);
        _updateLiquidityToInvest();
        _clearPurchasePrices();
        (uint256 amount, uint256 price) = _buyStrategyAsset();
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
        (uint256 amount, uint256 price) = _buyStrategyAsset();
        purchasePrices[price] += amount;
        lastAveragePrice = _getAveragePrice();
    }

    // @MARIA CHECK LOGIC OF THE FUNCTION!
    // has to be registered for timebase logic inside chainlink app
    // every 5 minutes or shorter if possible
    function takeProfit() private {
        require(!isStrategyExited, "Strategy exited");
        require((lastAveragePrice * strategyParams[strategyOption].targetPrice3.priceIncreasePercentage * 100) >= 10_000, "basis points to small");
        // HERE startegyAssetPrice has to be switched with oracle price feed 
        if (getEthUsdPrice() >= lastAveragePrice + 
        (lastAveragePrice * (strategyParams[strategyOption].targetPrice3.priceIncreasePercentage * 100)
        / 10_000)) {
            underlyingAssetOnProfitTotal += _sellStrategyAsset(address(this).balance, strategyParams[strategyOption].targetPrice3.sellPercentage);
        } else if (getEthUsdPrice() >= lastAveragePrice + 
        (lastAveragePrice * (strategyParams[strategyOption].targetPrice2.priceIncreasePercentage * 100)
        / 10_000)) {
            underlyingAssetOnProfitTotal += _sellStrategyAsset(address(this).balance, strategyParams[strategyOption].targetPrice2.sellPercentage);
        } else if (getEthUsdPrice() >= lastAveragePrice + 
        (lastAveragePrice * (strategyParams[strategyOption].targetPrice1.priceIncreasePercentage * 100)
        / 10_000)) {
            underlyingAssetOnProfitTotal += _sellStrategyAsset(address(this).balance, strategyParams[strategyOption].targetPrice1.sellPercentage);
        }
    }

    function stopLoss() private {
        require(!isStrategyExited);
        // CHECK IF ETH PRICE GOES TO TARGET PRICE THEN TRIGGER IT
        _sellStrategyAsset(address(this).balance, uint256(100));
        isSetModeEnabled = true;
        isStrategyStopped = true;
    }

    // Students functions
    /// @dev Sets the mode for the calling student.
    function setStudentMode(StudentMode newMode) public onlyStudents {
        studentsMode[msg.sender] = newMode;
        if (newMode == StudentMode.SAVE_ONLY) {
            // TODO use the  ERC function to get a user underlying asset balance
            saveOnlyTotal += getStudentUnderlyingAssetBalance();
        }
    }

    // TODO!!!
    function getStudentUnderlyingAssetBalance() public view returns(uint256){
        return 0;
    }

    function _sellStrategyAsset(uint256 total, uint256 percentageToSell) private returns (uint256 receivedAmount) {
        uint256 amountToSwitch = _calculateAbsoluteAmountfromPercentage(total, percentageToSell);
        ( , receivedAmount) = _switchAssets(strategyAsset, underlyingAsset, amountToSwitch);
        return receivedAmount;
    }

    function _buyStrategyAsset() private returns (uint256 price, uint256 receivedAmount) {
        return _switchAssets(underlyingAsset, strategyAsset, liquidityToInvest);
    }

    //TODO
    function _switchAssets(address assetOut, address assetIn, uint amountofAssetOut) private returns (uint price, uint256 receivedAmount) {
        // TODO declare and implement function
        // return aave.switchTokens();
        return 0;
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
    
    // returns the the Average price of the all bought weekly investments
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

    // TODO implement this function
    function _updateLiquidityToInvest() private {
        // From vaults balance of GHO substract the saveOnly amount

    }

    function _clearPurchasePrices() private {
        for (uint256 i = 0; i < prices.length; i++) {
            purchasePrices[prices[i]] = false;
        }
    }

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

    // Ballot functions
    function voteStrategyOption(StrategyOption votedOption) public {
        if (!_isStudent(msg.sender)) {
            revert NotAStudent();
        }
        if (studentHasVoted[msg.sender]) {
            revert StudentHasVoted();
        }
        if (votedOption == StrategyOption.CONSERVATIVE) {
            conservativeVotes += 1;
        } else if (votedOption == StrategyOption.MODERATE) {
            moderateVotes += 1;
        } else {
            aggressiveVotes += 1;
        }
    }

    function setWinningOption() public view onlyOwner returns (StrategyOption) {
        uint256 mostVoted = conservativeVotes;
        uint256 secondMostVoted = moderateVotes;

        if (moderateVotes > mostVoted) {
            mostVoted = moderateVotes;
            secondMostVoted = conservativeVotes;
        }

        if (aggressiveVotes > mostVoted) {
            secondMostVoted = mostVoted;
            mostVoted = aggressiveVotes;
        } else if (aggressiveVotes > secondMostVoted && aggressiveVotes != mostVoted) {
            secondMostVoted = aggressiveVotes;
        }

        if (mostVoted = secondMostVoted) {
            _resetVotingStatus();
            revert TieVoteAgain();
        }

        strategyOption = mostVoted;
        return mostVoted;
    }

    function _resetVotingStatus() public {
        for (uint256 i = 0; i < students.length; i++) {
            studentHasVoted[students[i]] = false;
        }
    }

    // Chainlink function for setting automation based on a timeinterval
    function checkUpkeep(bytes calldata /* checkData */) 
        external 
        view 
        override 
        returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastTimeStampAutomation) > intervalAutomation;
    }

    // Chainlink function to perform automation action
    function performUpkeep(bytes calldata /* performData */) external override {
        if ((block.timestamp - lastTimeStampAutomation) > intervalAutomation) {
            lastTimeStampAutomation = block.timestamp;
            purchaseWeekly();
            
        }
        // We don't use the performData in this example. The performData is generated by the Automation Node's call to your checkUpkeep function
    }

    function getEthUsdPrice() public view returns(int) {
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData(Denominations.ETH, Denomations.USD);
        return price;
    }

}


