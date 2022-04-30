// stake : Lock tokens into our smart contract
// withdraw : unlock tokens and pull out of the contract
// claimReward : users get their reward tokens

// what's a good reward mechanism?
// what's some good reward math ?

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Staking__TransferFailed();
error Staking__NeedMoreThanZero();

contract Staking {
    IERC20 public s_stakingToken;
    IERC20 public s_rewardToken;

    // someone address ---> how much the staked
    mapping(address => uint256) public s_balances;

    mapping(address => uint256) public s_rewards;

    mapping(address => uint256) public s_userRewardPerTokenPaid;

    uint256 public s_totalSupply;

    uint256 public s_rewardPerTokenStored;

    uint256 public s_lastUpdateTime;

    uint256 public constant REWARD_RATE = 100;

    modifier updateReward(address account) {
        s_rewardPerTokenStored = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        s_rewards[account] = earned(account);
        _;
    }

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) revert Staking__NeedMoreThanZero();
        _;
    }

    constructor(address stakingToken, address rewardToken) {
        s_stakingToken = IERC20(stakingToken);
        s_rewardToken = IERC20(rewardToken);
    }

    function earned(address account) public view returns (uint256) {
        uint256 currentBalance = s_balances[account];
        uint256 amountPaid = s_userRewardPerTokenPaid[account];
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 pastRewards = s_rewards[account];

        uint256 earnedRewards = (currentBalance *
            (currentRewardPerToken - amountPaid)) /
            1e18 +
            pastRewards;

        return earnedRewards;
    }

    function rewardPerToken() public view returns (uint256) {
        if (s_totalSupply == 0) {
            return s_rewardPerTokenStored;
        }
        return
            s_rewardPerTokenStored +
            (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18) /
                s_totalSupply);
    }

    // do we allow any tokens ? --- not allow any token.
    //          have to do chainlink stuff to convert prices between tokens.
    // or just a specific token? ✅
    function stake(uint256 amount)
        external
        updateReward(msg.sender)
        moreThanZero(amount)
    {
        // keep track of how much this user has staked
        // keep track of how much token we have total
        // transfer the tokens to this contract
        s_balances[msg.sender] = s_balances[msg.sender] + amount;
        s_totalSupply = s_totalSupply + amount;
        // emit event
        bool success = s_stakingToken.transferFrom(
            msg.sender,
            address(this),
            amount
        );

        // instead of require
        // revert ==> it reverts all the changes done above in this function call
        if (!success) {
            revert Staking__TransferFailed();
        }
    }

    function withdraw(uint256 amount) external updateReward(msg.sender) {
        s_balances[msg.sender] = s_balances[msg.sender] - amount;
        s_totalSupply = s_totalSupply - amount;
        bool success = s_stakingToken.transfer(msg.sender, amount);
        if (!success) {
            revert Staking__TransferFailed();
        }
    }

    function claimReward() external updateReward(msg.sender) {
        uint256 reward = s_rewards[msg.sender];
        bool success = s_rewardToken.transfer(msg.sender, reward);
        if (!success) {
            revert Staking__TransferFailed();
        }
    }
}
