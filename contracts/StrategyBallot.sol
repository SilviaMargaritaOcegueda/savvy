// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./DataTypes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StrategyBallot is Ownable {
    uint256 conservativeVotes;
    uint256 moderateVotes;
    uint256 aggressiveVotes;
    DataTypes.StrategyOption public strategyOption;
    address[] students;
    // Associate student with a boolean indicating whether the student has already voted
    mapping(address => bool) public studentHasVoted;
    error NotAStudent();
    error StudentHasVoted();
    error TieVoteAgain();

    constructor(address _teacherAddress) Ownable(_teacherAddress) {}

    function voteStrategyOption(DataTypes.StrategyOption votedOption) public {
        if (!_isStudent(msg.sender)) {
            revert NotAStudent();
        }
        if (studentHasVoted[msg.sender]) {
            revert StudentHasVoted();
        }
        if (votedOption == DataTypes.StrategyOption.CONSERVATIVE) {
            conservativeVotes += 1;
        } else if (votedOption == DataTypes.StrategyOption.MODERATE) {
            moderateVotes += 1;
        } else {
            aggressiveVotes += 1;
        }
    }

    function setWinningOption() public onlyOwner returns (DataTypes.StrategyOption) {
        uint256 mostVoted = conservativeVotes;
        uint256 secondMostVoted = moderateVotes;
        strategyOption = DataTypes.StrategyOption.CONSERVATIVE;

        if (moderateVotes > mostVoted) {
            mostVoted = moderateVotes;
            secondMostVoted = conservativeVotes;
            strategyOption = DataTypes.StrategyOption.MODERATE;
        }
        if (aggressiveVotes > mostVoted) {
            secondMostVoted = mostVoted;
            mostVoted = aggressiveVotes;
            strategyOption = DataTypes.StrategyOption.AGGRESSIVE;
        } else if (aggressiveVotes > secondMostVoted && aggressiveVotes != mostVoted) {
            secondMostVoted = aggressiveVotes;
        }
        if (mostVoted == secondMostVoted) {
            revert TieVoteAgain();
        }
        return strategyOption;
    }

    function resetVotingStatus() public onlyOwner {
        for (uint256 i = 0; i < students.length; i++) {
            studentHasVoted[students[i]] = false;
        }
    }

    // Modifier to check if the message sender is a student
    modifier onlyStudents() {
        if (!_isStudent(msg.sender)) {
            revert NotAStudent();
        }
        _;
    }

     // Function to check if an address is a student
    function _isStudent(address _address) internal view returns(bool) {
        for (uint i = 0; i < students.length; i++) {
            if (students[i] == _address) {
                return true;
            }
        }
        return false;
    }
}