// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./utils/DataTypes.sol";
import "./StrategyBallot.sol";
import "./ERC4626.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// Sepolia 
// ETH / USD 0x694AA1769357215DE4FAC081bf1f309aDC325306
// GHO / USD 0x635A86F9fdD16Ff09A0701C305D3a845F1758b8E
// chainlink automation 
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HodlVault is 
    ERC20,
    AutomationCompatibleInterface, 
    StrategyBallot, 
    ERC4626 
{
    using Math for uint256;

    event Profit(uint256 tier, uint256 price, uint256 soldAmount);

    event StopLoss(
        uint256 price,
        uint256 receivedAmount
    );

    address public immutable strategyAsset;
    address public immutable underlyingAsset;
    address payable public classAddress;
    uint256 public immutable firstPurchaseTimestamp;
    uint256 public immutable finalPurchaseTimestamp;
    uint256 public immutable finalWithdrawalTimestamp;
    uint256 public strategyAssetPrice;
    uint256 public lastAveragePrice;
    uint256 public weeklyAmount;
    uint256 liquidityToInvest;
    uint256 saveOnlyTotal;
    uint256 underlyingAssetOnProfitTotal;
    bool public isClaimEnabled = false;
    bool public isSetModeEnabled = false;
    bool public isStrategyExited = false;
    bool public isStrategyStopped = false;

    // to access Eth price from chainlink
    AggregatorV3Interface internal dataFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    // Use an interval in seconds and a timestamp to slow execution of Upkeep
    uint256 public immutable intervalAutomation = 604_800;
    uint256 public lastTimeStampAutomation;

    // Associates each strategy option with its parameters
    mapping(DataTypes.StrategyOption => DataTypes.StrategyParams) public strategyParams;

    uint256[] public prices;
    // Associates each purchase price with the amount of strategy asset purchased at that price
    mapping(uint256 => uint256) public purchasePrices;

    // TODO when student supplies liquidity check his status to either add the balance 
    // to liquidityToInvest or to saveOnlyTotal  
    // Associates each student address with their mode
    mapping(address => DataTypes.StudentMode) public studentsMode;  

    /// @dev Initializes the HodlStaticTokenVault contract with the provided parameters.
    constructor(
        uint256 _weeklyAmount,
        uint256 _initialDepositTimestamp,
        uint256 _finalDepositTimestamp,
        address _strategyAsset,
        address _underlyingAsset,
        address _classAddress,
        address _teacherAddress,
        address[] memory _students
    ) StrategyBallot(_teacherAddress) ERC4626(_underlyingAsset) ERC20('savvyGHO', 'sGHO') {
        firstPurchaseTimestamp = _initialDepositTimestamp + 1 days;
        finalPurchaseTimestamp = _finalDepositTimestamp + 1 days;
        lastTimeStampAutomation = finalPurchaseTimestamp + 1 days;
        finalWithdrawalTimestamp = lastTimeStampAutomation + 90 days;
        strategyAsset = _strategyAsset;
        underlyingAsset = _underlyingAsset;
        students = _students;
        classAddress = payable(_classAddress);
        weeklyAmount = _weeklyAmount;
    }

    // only owner functions

    /// @dev After a stop loss event, restarts the strategy with the new provided strategy option.
    function restartStrategy(DataTypes.StrategyOption newStrategy) public onlyOwner {
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
        _sellStrategyAsset(address(this).balance, 10_000);
        _enableClaim();
        isStrategyExited = true;
    }

    /// @dev Sends remaining ETH balance to the class address 
    function withdrawAll() public onlyOwner {
        require(block.timestamp >= finalWithdrawalTimestamp, "Too early to destroy");
        uint256 remainingEthBalance = address(this).balance;
        require(address(this).balance > 0, "Contract balance is empty");
        classAddress.transfer(remainingEthBalance);
    }

    // Automated actions
    function purchaseWeekly() private {
        require(!isStrategyExited, "Strategy exited");
        (uint256 amount, uint256 price) = _buyStrategyAsset();
        purchasePrices[price] += amount;
        lastAveragePrice = _getAveragePrice();
    }

    function takeProfit() private {
        require(!isStrategyExited, "Strategy exited");
        require((lastAveragePrice * strategyParams[strategyOption].targetPrice3.priceIncreaseBasisPoints) >= 10_000, "Price increment rounds to zero");
        // TODO Here startegyAssetPrice has to be switched with oracle price feed 
        // if (getEthUsdPrice() >= lastAveragePrice + 
        // (lastAveragePrice * (DataTypes.strategyParams[DataTypes.strategyOption].targetPrice3.priceIncreaseBasisPoints) / 10_000)) {
        //     underlyingAssetOnProfitTotal += _sellStrategyAsset(address(this).balance, DataTypes.strategyParams[DataTypes.strategyOption].targetPrice3.sellBasisPoints);
        // emit Profit(3, price, receivedAmount);
        // } else if (getEthUsdPrice() >= lastAveragePrice + 
        // (lastAveragePrice * (DataTypes.strategyParams[DataTypes.strategyOption].targetPrice2.priceIncreaseBasisPoints) / 10_000)) {
        //     underlyingAssetOnProfitTotal += _sellStrategyAsset(address(this).balance, DataTypes.strategyParams[DataTypes.strategyOption].targetPrice2.sellBasisPoints);
        // emit Profit(2, price, receivedAmount);
        // } else if (getEthUsdPrice() >= lastAveragePrice + 
        // (lastAveragePrice * (DataTypes.strategyParams[DataTypes.strategyOption].targetPrice1.priceIncreaseBasisPoints) / 10_000)) {
        //     underlyingAssetOnProfitTotal += _sellStrategyAsset(address(this).balance, DataTypes.strategyParams[DataTypes.strategyOption].targetPrice1.sellBasisPoints);
        // emit Profit(1, price, receivedAmount);
        // }
    }

    function stopLoss() private {
        require(!isStrategyExited);
        (uint256 price, uint256 receivedAmount) = _sellStrategyAsset(address(this).balance, 10_000);
        isSetModeEnabled = true;
        isStrategyStopped = true;
        emit StopLoss(price, receivedAmount);
    }

    // Students functions
    /// @dev Sets the mode for the calling student.
    function setStudentMode(DataTypes.StudentMode newMode) public onlyStudents {
        studentsMode[msg.sender] = newMode;
        if (newMode == DataTypes.StudentMode.SAVE_ONLY) {
            // TODO use the  ERC function to get a user underlying asset balance
            saveOnlyTotal += getStudentUnderlyingAssetBalance();
        }
    }

    // TODO!!!
    function getStudentUnderlyingAssetBalance() public pure returns(uint256){
        return 0;
    }

    function _sellStrategyAsset(uint256 total, uint256 bpsToSell) private returns (uint256 price, uint256 receivedAmount) {
        uint256 amountToSwitch = _calculateAmountfromBasisPoints(total, bpsToSell);
        return _switchAssets(strategyAsset, underlyingAsset, amountToSwitch);
    }

    function _buyStrategyAsset() private returns (uint256 price, uint256 receivedAmount) {
        return _switchAssets(underlyingAsset, strategyAsset, liquidityToInvest);
    }

    //TODO
    function _switchAssets(address assetOut, address assetIn, uint amountofAssetOut) private returns (uint price, uint256 receivedAmount) {
        // TODO declare and implement function
        // return aave.switchTokens();
        // return 0;
    }

    // Helper functions
    function _enableClaim() private {
        isClaimEnabled = true;
    }

    function _disableClaim() private {
        isClaimEnabled = false;
    }

    // Adds students' addresses to the list of students.
    function _addStudents(address[] calldata newStudents) private {
        for (uint i = 0; i < newStudents.length; i++) {
            students.push(newStudents[i]);
        }
    }

    function _calculateAmountfromBasisPoints(uint256 total, uint256 bpsToSell) private pure returns (uint256) {
        require((total * bpsToSell) >= 10_000);
        return total * bpsToSell / 10_000;
    }
    
    function _getAveragePrice() internal view returns (uint256) {
        uint256 totalValue = 0;
        uint256 totalAmount = 0;

        for (uint256 i = 0; i < prices.length; i++) {
            totalValue += prices[i] * purchasePrices[prices[i]];
            totalAmount += purchasePrices[prices[i]];
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
            purchasePrices[prices[i]] = 0;
        }
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
    
    // Chainlink function for setting automation based on a timeinterval
    function checkUpkeep(bytes calldata /* checkData */) 
        external 
        view 
        override 
        returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastTimeStampAutomation) > intervalAutomation;
        // uint256 currentPrice=getOraclePrice();
        // Maria, exitPrice depends on the strategy option is a percentage(now bps) of the average price
        // if (currentPrice <= exitPrice ){
        //     stopLoss();
        // }    
    }

    // Chainlink function to perform automation action
    function performUpkeep(bytes calldata /* performData */) external override {
        if ((block.timestamp - lastTimeStampAutomation) > intervalAutomation) {
            lastTimeStampAutomation = block.timestamp;
            purchaseWeekly();
            
        }
        // We don't use the performData in this example. The performData is generated by the Automation Node's call to your checkUpkeep function
    }

    function getOraclePrice() public view returns(int) {
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view virtual override returns (uint256) {
        return assets;
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual override returns (uint256) {
        (, bytes memory encodedBalance) = asset().staticcall(
            abi.encodeCall(IERC20.balanceOf, address(this))
        );
        uint256 returnedBalance = abi.decode(encodedBalance, (uint256));
        return shares.mulDiv(returnedBalance + 1, totalSupply() + 10 ** _decimalsOffset(), rounding);
    }
}


