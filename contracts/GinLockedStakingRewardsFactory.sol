pragma solidity ^0.5.16;

import "./access/Ownable.sol";
import "./GinLockedStakingRewards.sol";

contract GinLockedStakingRewardsFactory is Ownable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // immutables
    address public rewardsToken;
    // uint public stakingRewardsGenesis; 

    // info about rewards for a particular staking token
    struct StakingRewardsInfo {
        address stakingToken;
        address stakingRewards;
        uint rewardAmount;
        uint256 boostMultipler;
        uint256 deployAt;
    }

    StakingRewardsInfo[] public stakingRewardsInfoList;

    constructor(
        address _rewardsToken
        // uint _stakingRewardsGenesis
    ) Ownable() public {
        // require(_stakingRewardsGenesis >= block.timestamp, 'GinLockedStakingRewards::constructor: genesis too soon');

        rewardsToken = _rewardsToken;
        // stakingRewardsGenesis = _stakingRewardsGenesis;
    }

    ///// permissioned functions

    // deploy a staking reward contract for the staking token, and store the reward amount
    // the reward will be distributed to the staking reward contract no sooner than the genesis
    // rewardDuration takes the time as second, 1 day = 86400
    function deploy(address stakingToken, uint rewardAmount, uint256 rewardDuration, uint256 lockPeriod, uint256 cooldownPeriod, uint256 boostMultipler) public onlyOwner {
        
        StakingRewardsInfo memory info;

        info.stakingRewards = address(new GinLockedStakingRewards(address(this), rewardsToken, stakingToken, rewardDuration, lockPeriod, cooldownPeriod, boostMultipler));
        info.rewardAmount = rewardAmount;
        info.deployAt = block.timestamp;
        info.stakingToken = stakingToken;
        info.boostMultipler = boostMultipler;

        stakingRewardsInfoList.push(info);

        emit PoolDeployed(stakingRewardsInfoList.length - 1, stakingToken, info.stakingRewards, rewardAmount, rewardDuration);
    }

    ///// permissionless functions

    // call notifyRewardAmount for all staking tokens.
    function notifyRewardAmounts() public {
        require(stakingRewardsInfoList.length > 0, 'GinLockedStakingRewards::notifyRewardAmounts: called before any deploys');
        for (uint i = 0; i < stakingRewardsInfoList.length; i++) {
            notifyRewardAmount(i);
        }
    }

    // notify reward amount for an individual staking token.
    // this is a fallback in case the notifyRewardAmounts costs too much gas to call for all contracts
    function notifyRewardAmount(uint256 index) public {
        // require(block.timestamp >= stakingRewardsGenesis, 'GinLockedStakingRewards::notifyRewardAmount: not ready');
        require(index < stakingRewardsInfoList.length, 'GinLockedStakingRewards::notifyRewardAmount: index out of range');

        StakingRewardsInfo storage info = stakingRewardsInfoList[index];
        require(info.stakingRewards != address(0), 'GinLockedStakingRewards::notifyRewardAmount: not deployed');

        if (info.rewardAmount > 0) {
            uint rewardAmount = info.rewardAmount;
            info.rewardAmount = 0;

            IERC20(rewardsToken).safeTransfer(info.stakingRewards, rewardAmount.add(rewardAmount.mul(info.boostMultipler)));
            GinLockedStakingRewards(info.stakingRewards).notifyRewardAmount(rewardAmount);
            emit RewardNotified(index, rewardAmount);
        }
    }

    function extendStakingRewards(uint256 index, uint256 rewardAmount) external onlyOwner {
        // require(block.timestamp >= stakingRewardsGenesis, 'GinLockedStakingRewards::extendStakingRewards: not ready');
        require(index < stakingRewardsInfoList.length, 'GinLockedStakingRewards::extendStakingRewards: incorrect index');
        require(rewardAmount > 0, 'GinLockedStakingRewards::extendStakingRewards: incorrect rewardAmount');

        StakingRewardsInfo storage info = stakingRewardsInfoList[index];
        require(info.stakingRewards != address(0), 'GinLockedStakingRewards::extendStakingRewards: not deployed');
        require(info.rewardAmount == 0, 'GinLockedStakingRewards::extendStakingRewards: not started');

        IERC20(rewardsToken).safeTransfer(info.stakingRewards, rewardAmount);
        GinLockedStakingRewards(info.stakingRewards).notifyRewardAmount(rewardAmount);
        emit PoolExtended(index, rewardAmount);
    }

    function stakingRewardsInfoListLength() external view returns (uint256) {
        return stakingRewardsInfoList.length;
    }

    event PoolDeployed(uint256 poolIndex, address stakingToken, address stakingReward, uint256 rewardAmount, uint256 duration);
    event PoolExtended(uint256 poolIndex, uint256 rewardAmount);
    event RewardNotified(uint256 poolIndex, uint256 rewardAmount);
}