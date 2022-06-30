pragma solidity ^0.5.16;

interface IGinLockedStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function restakeByIndex(uint256 index) external;

    function restakeAll() external;

    function startAllCooldown() external;
    
    function startCooldownByIndex(uint256 index) external;

    function withdrawIndex(uint256 index) external;

    function withdrawAllUnlocked() external;

    // function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}