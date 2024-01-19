// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2;

/**
 * @title StakingVault
 * @dev Create Vault & stake based on agiven strategy
 * @custom:
 */

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";

contract SavvyStakingVault is ERC4626, Ownable {

    // a mapping that checks if a user has deposited the token
    mapping(address => uint256) public shareHolder;
    
    address[] studentsLists;
    // prices 

    // mapping of earnings from staking? 
    mapping(address => uint256) public cumulatedEarnings;

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
    IPool public immutable POOL;

    // WETH-TestnetPriceAggregator-Aave     │ '0xDde0E8E6d3653614878Bf5009EDC317BC129fE2F' │
    // WETH-AToken-Aave             │ '0x5b071b590a59395fE4025A0Ccc1FcC931AAc1830' │
    // WETH-VariableDebtToken-Aave       │ '0x22a35DB253f4F6D0029025D6312A3BdAb20C2c6A' │
    // WETH-StableDebtToken-Aave        │ '0xEb45D5A0efF06fFb88f6A70811c08375A8de84A3' │
    // WETH-TestnetMintableERC20-Aave │ '0xC558DBdd856501FCd9aaF1E62eae57A9F0629a3c' │
    
    // TODO Find the correct address for ETH!
    address private immutable ethAddress =
        0x07C725d58437504CA5f814AE406e70E21C5e8e9e;
    IERC20 private eth;

    // combine ethAdress and _asset
    constructor(
        IERC20 _asset, 
        string memory _name, 
        string memory _symbol,
        address _initialOwner,
        address _addressProvider
    ) ERC4626 (_asset) ERC20(_name, _symbol) Ownable(_initialOwner) {
        ADDRESSES_PROVIDER = IPoolAddressesProvider(_addressProvider);
        POOL = IPool(ADDRESSES_PROVIDER.getPool());
    }

    function addStudents(address[] memory students) public {
         studentsLists = students;
    }

    function emergencyExit () public onlyOwner {
         // stop staking and refund back
    }
    
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        uint256 maxAssets = maxDeposit(receiver);

        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    

    function supplyLiquidity(address _tokenAddress, uint256 _amount, address _studentaddress) external {
        address asset = _tokenAddress;
        uint256 amount = _amount;
        address onBehalfOf = _studentaddress;
        uint16 referralCode = 0;

        POOL.supply(asset, amount, onBehalfOf, referralCode);
    }

    //  function to withdrawl liquidity 
    // if amount is higher than balance ... will be thrown
    function withdrawlLiquidity(address _tokenAddress, uint256 _amount, address _studentaddress)
        external
        returns (uint256)
    {   
        address asset = _tokenAddress;
        uint256 amount = _amount;
        address to = _studentaddress;

        return POOL.withdraw(asset, amount, to);
    }

    function getUserAccountData(address _userAddress)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        return POOL.getUserAccountData(_userAddress);
    }

    /////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    function approveETH(uint256 _amount, address _poolContractAddress)
        external
        returns (bool)
    {
        return eth.approve(_poolContractAddress, _amount);
    }

    function allowanceETH(address _poolContractAddress)
        external
        view
        returns (uint256)
    {
        return eth.allowance(address(this), _poolContractAddress);
    }

    function getBalance(address _tokenAddress) external view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function withdraw(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}