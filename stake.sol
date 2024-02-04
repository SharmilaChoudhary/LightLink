/ SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Staking {
    using SafeMath for uint256;

    IERC20 public token;  // The ERC-20 token to be staked
    address public owner; // Contract owner

    mapping(address => uint256) public stakingBalance;
    mapping(address => uint256) public stakingTimestamp;

    uint256 public rewardRate = 1; // Reward rate per second (adjust as needed)
    uint256 public stakingDuration = 30 days;

    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount, uint256 reward);

    constructor(address _token) {
        token = IERC20(_token);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        // Transfer tokens from the sender to the contract
        token.transferFrom(msg.sender, address(this), amount);

        // If user already has a staking balance, calculate and send the reward
        if (stakingBalance[msg.sender] > 0) {
            uint256 reward = calculateReward(msg.sender);
            if (reward > 0) {
                token.transfer(msg.sender, reward);
                emit Unstaked(msg.sender, 0, reward);
            }
        }

        // Update staking balance and timestamp
        stakingBalance[msg.sender] = stakingBalance[msg.sender].add(amount);
        stakingTimestamp[msg.sender] = block.timestamp;

        emit Staked(msg.sender, amount);
    }

    function unstake() external {
        require(stakingBalance[msg.sender] > 0, "Nothing to unstake");

        // Calculate and send the reward
        uint256 reward = calculateReward(msg.sender);
        if (reward > 0) {
            token.transfer(msg.sender, reward);
        }

        // Transfer staked amount back to the user
        uint256 amountToUnstake = stakingBalance[msg.sender];
        stakingBalance[msg.sender] = 0;

        emit Unstaked(msg.sender, amountToUnstake, reward);

        token.transfer(msg.sender, amountToUnstake);
    }

    function calculateReward(address staker) internal view returns (uint256) {
        uint256 stakingTime = block.timestamp - stakingTimestamp[staker];
        return stakingBalance[staker].mul(rewardRate).mul(stakingTime).div(stakingDuration);
    }

    // Function to view the current reward without claiming
    function viewCurrentReward(address staker) external view returns (uint256) {
        return calculateReward(staker);
    }

    // Function to withdraw any remaining tokens from the contract (onlyOwner)
    function withdrawTokens(address recipient, uint256 amount) external onlyOwner {
        token.transfer(recipient, amount);
    }
}
