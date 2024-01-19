// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma abicoder v2;

import "./StrategyBallot.sol";
import "./utils/DataTypes.sol";
import "./utils/Constants.sol";
import "./StrategyTargetPrices.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract HodlVault is 
    AutomationCompatibleInterface, 
    StrategyBallot, 
    ERC4626,
    StrategyTargetPrices
{
    using Math for uint256;

    string public strategyName;
    bytes pathToBuy;
    address payable public classAddress;
    uint256 public immutable firstPurchaseTimestamp;
    uint256 public immutable finalPurchaseTimestamp;
    uint256 public immutable finalWithdrawalTimestamp;
    uint256 public weeklyAmount;
    uint256 liquidityToInvest;
    uint256 saveOnlyTotal;
    bool public isClaimEnabled = false;
    
    // Use an interval (one week in seconds) and a timestamp to slow execution of Upkeep
    uint256 public immutable intervalAutomation = 604_800;
    uint256 public lastTimeStampAutomation;

    uint256[] public prices;
    // Associates each purchase price with the amount of strategy asset purchased at that price
    mapping(uint256 => uint256) public purchasePrices;

    // Associates each student address with their mode
    mapping(address => DataTypes.StudentMode) public studentsMode;  
    // Associates each student address with their balance on saveOnly mode
    mapping(address => uint256) public saveOnlybalances;

    error ClaimsDisabled();

    /// @dev Initializes the HodlStaticTokenVault contract with the provided parameters.
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
    ) StrategyBallot(_teacherAddress) 
        ERC4626(IERC20(_underlyingAsset)) 
        ERC20('savvyGHO', 'sGHO') 
        StrategyTargetPrices(_aggregator, _swapRouter, _underlyingAsset, _strategyAsset) {
        strategyName = _strategyName;
        firstPurchaseTimestamp = _initialDepositTimestamp + 1 days;
        finalPurchaseTimestamp = _finalDepositTimestamp + 1 days;
        lastTimeStampAutomation = finalPurchaseTimestamp + 1 days;
        finalWithdrawalTimestamp = lastTimeStampAutomation + 90 days;
        students = _students;
        classAddress = payable(_classAddress);
        weeklyAmount = _weeklyAmount;
    }

    /// @dev Sends remaining ETH balance to the class address 
    function withdrawAll() external onlyOwner {
        require(block.timestamp >= finalWithdrawalTimestamp, "Too early to destroy");
        uint256 remainingEthBalance = address(this).balance;
        require(address(this).balance > 0, "Contract balance is empty");
        classAddress.transfer(remainingEthBalance);
    }

    // Automated actions
    function _purchaseWeekly() private {
        require(!isStrategyExited, "Strategy exited");
        (uint256 amount, uint256 price) = _buyStrategyAsset();
        purchasePrices[price] += amount;
        lastAveragePrice = getAveragePrice();
    }

    /// @dev Sets the mode for the calling student.
    function setStudentMode(DataTypes.StudentMode newMode) external onlyStudents {
        studentsMode[_msgSender()] = newMode;
        if (newMode == DataTypes.StudentMode.SAVE_ONLY) {
            uint256 studentBalance = convertToAssets(balanceOf(_msgSender()));
            saveOnlyTotal += studentBalance;
            saveOnlybalances[_msgSender()] = studentBalance; 
        }
    }

    function deposit(
        uint256 assets, 
        address receiver
    ) public virtual override onlyStudents returns (uint256) {
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }
        
        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);
        if (studentsMode[_msgSender()] == DataTypes.StudentMode.SAVE_ONLY) {
            saveOnlybalances[_msgSender()] += assets;
        } else {
            liquidityToInvest += assets;
        }

        return shares;
    }

    function withdraw(
        uint256 assets, 
        address receiver, 
        address owner
    ) public virtual override onlyStudents returns (uint256) {
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        uint256 shares;
        if (assets == maxAssets) {
            shares = balanceOf(owner);
        } else {
            shares = assets.mulDiv(balanceOf(owner), maxAssets, Math.Rounding.Ceil);
        }
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        uint256 assets;
        if (studentsMode[owner] == DataTypes.StudentMode.SAVE_ONLY) {
            assets = saveOnlybalances[owner];
        } else {
            assets = 
            balanceOf(owner).mulDiv(_thisBalanceOfUnderlyingAsset() - saveOnlyTotal, totalSupply(), Math.Rounding.Floor);
        }
        
        return assets;
    }

    function redeem(
        uint256 shares, 
        address receiver, 
        address owner
    ) public virtual override onlyStudents returns (uint256) {
        if (!isClaimEnabled) {
            revert ClaimsDisabled();
        }
        
        uint256 maxShares = maxRedeem(owner);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
        }
        
        uint256 assets;
        if (studentsMode[owner] == DataTypes.StudentMode.SAVE_ONLY) {
            assets = shares.mulDiv(saveOnlybalances[owner], balanceOf(owner), Math.Rounding.Floor);
        } else {
            assets = shares.mulDiv(_thisBalanceOfUnderlyingAsset() - saveOnlyTotal, totalSupply(), Math.Rounding.Floor);
        }
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /// @dev After a stop loss event, restarts the strategy with the new provided strategy option.
    function restartStrategy(DataTypes.StrategyOption newStrategy) external onlyOwner {
        require(isStrategyStopped);
        _updateLiquidityToInvest();
        _clearPurchasePrices();
        (uint256 amount, uint256 price) = _buyStrategyAsset();
        purchasePrices[price] += amount;
        lastAveragePrice = getAveragePrice();
        strategyOption = newStrategy;
        isStrategyExited = false; 
    }
    
    /// @dev Sells remaining holdings and enables claims
    function emergencyExit() external onlyOwner {
        sellStrategyAsset(address(this).balance, 10_000);
        _enableClaim();
        isStrategyExited = true;
    }

    function _convertToShares(uint256 assets, Math.Rounding /* rounding */) internal view virtual override returns (uint256) {
        return assets;
    }

    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual override returns (uint256) {
        uint256 returnedBalance = _thisBalanceOfUnderlyingAsset();
        return shares.mulDiv(returnedBalance + 1, totalSupply() + 10 ** _decimalsOffset(), rounding);
    }

    function _buyStrategyAsset() private returns (uint256 price, uint256 receivedAmount) {
        if(strategyAsset == Constants.WETH9) {
            return swapExactInputMultihop(asset(), liquidityToInvest, Constants.BUY_WETH_PATH);
        } else {
            return swapExactInputMultihop(asset(), liquidityToInvest, Constants.BUY_RETH_PATH);
        }
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
    
    function getAveragePrice() public view returns (uint256) {
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

    function _updateLiquidityToInvest() private {
        saveOnlyTotal = 0;
        for (uint256 i = 0; i < students.length; i++) {
            if (studentsMode[students[i]] == DataTypes.StudentMode.SAVE_ONLY) {
                saveOnlyTotal += convertToAssets(balanceOf(students[i]));
            }
        }
        liquidityToInvest = _thisBalanceOfUnderlyingAsset() - saveOnlyTotal;
    }

    // Vault's balance of the underlying asset
    function _thisBalanceOfUnderlyingAsset() private view returns (uint256) {
        (, bytes memory encodedBalance) = asset().staticcall(
            abi.encodeCall(IERC20.balanceOf, address(this))
        );
        return abi.decode(encodedBalance, (uint256));
    }

    function _clearPurchasePrices() private {
        for (uint256 i = 0; i < prices.length; i++) {
            purchasePrices[prices[i]] = 0;
        }
    }

    // Chainlink function for setting automation based on a timeinterval cause 
    // purchaseweekly has to be resticted called from inside the contract
    // and based on conditions regarding price
    function checkUpkeep(bytes calldata checkData) 
        external 
        view 
        override 
        returns (bool upkeepNeeded, bytes memory performData) {
        if(keccak256(checkData) == keccak256(hex'01')){
            upkeepNeeded = (block.timestamp - lastTimeStampAutomation) > intervalAutomation;
            performData = checkData;
        }
        if(keccak256(checkData) == keccak256(hex'02')) { 
            uint256 currentPrice = getOraclePrice();
            uint256 exitPrice = getAveragePrice() - (getAveragePrice() * (strategyParams[strategyOption].priceDecreaseBasisPoints) / 10_000);
            upkeepNeeded = (currentPrice <= exitPrice);
        }
        if(keccak256(checkData) == keccak256(hex'03')) {
            (uint256 targetPrice3, uint256 targetPrice2, uint256 targetPrice1) = getTargetPrices(strategyOption);
            upkeepNeeded = ((getOraclePrice() >= targetPrice3) ||
                (getOraclePrice() >= targetPrice2) ||
                (getOraclePrice() >= targetPrice1)); 
            performData = checkData;
        }
    }

    // Chainlink function to perform automation action
    function performUpkeep(bytes calldata performData) external override {
        if(keccak256(performData) == keccak256(hex'01')){
            if ((block.timestamp - lastTimeStampAutomation) > intervalAutomation) {
                lastTimeStampAutomation = block.timestamp;
                _purchaseWeekly();
            }
        }
        if(keccak256(performData) == keccak256(hex'02')) {
            uint256 currentPrice = getOraclePrice();
            uint256 exitPrice = getAveragePrice() - (getAveragePrice() * (strategyParams[strategyOption].priceDecreaseBasisPoints) / 10_000);
            if (currentPrice <= exitPrice) {
                stopLoss();
            }
        }
        if(keccak256(performData) == keccak256(hex'03')) {
            (uint256 targetPrice3, uint256 targetPrice2, uint256 targetPrice1) = getTargetPrices(strategyOption);
            if(((getOraclePrice() >= targetPrice3) ||
                (getOraclePrice() >= targetPrice2) ||
                (getOraclePrice() >= targetPrice1)))
                {
                takeProfit(strategyOption);
            }
        }
    }
}
