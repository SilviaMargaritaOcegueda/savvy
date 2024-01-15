// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2;

/**
 * @title StakingVault
 * @dev Create Vault & stake based on agiven strategy
 * @custom:
 */

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract SavvyStakingVault is ERC4626, Ownable {

    // a mapping that checks if a user has deposited the token
    mapping(address => uint256) public shareHolder;
    
    address[] studentsLists;
    // prices 

    // mapping of earnings from staking? 
    mapping(address => uint256) public cumulatedEarnings;


    constructor(
        IERC20 _asset, 
        string memory _name, 
        string memory _symbol,
        address _initialOwner
    ) ERC4626 (_asset) ERC20(_name, _symbol) Ownable(_initialOwner){

    }

    //function addVault() {}
    //function stake () external {}
    //function startegie (){}
    //function unstake () external {}
    function addStudents(address[] memory students) public {
         studentsLists = students;
    }

    function emergencyExit () public onlyOwner {
         // stop staking and refund back
    }

    // function stake() public onlyOwner {

    // }

    // function unstake() {

    // }

    // function claim() {

    // }
}