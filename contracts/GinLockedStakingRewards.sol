pragma solidity ^0.5.16;

import "./libraries/Math.sol";
import "./access/Ownable.sol";
import "./utils/ReentrancyGuard.sol";
import "./libraries/SafeMath.sol";
import "./libraries/Address.sol";
import "./libraries/SafeERC20.sol";
import "./RewardLocker.sol";
import "./RewardsDistributionRecipient.sol";
import "./interfaces/IGinLockedStakingRewards.sol";

contract GinLockedStakingRewards is IGinLockedStakingRewards, RewardsDistributionRecipient, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public boostMultipler = 0;
    uint256 public lockPeriod = 0;
    uint256 public cooldownPeriod = 0;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 30 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    struct LockData {
        uint256 locked;
        uint256 startAt;
        uint256 endAt;
        uint256 unlocked;
        uint256 cooldownStartAt;
        uint256 cooldownEndAt;
        bool restaked;
    }

    mapping(address => LockData[]) public lockedList;
    mapping(address => uint256) public lockedListLen;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    uint256 private _supplyInCooldown;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _balancesInCooldown;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        uint256 _rewardsDuration,
        uint256 _lockPeriod,
        uint256 _cooldownPeriod,
        uint256 _boostMultipler
    ) public {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        rewardsDuration = _rewardsDuration;
        lockPeriod = _lockPeriod;
        cooldownPeriod = _cooldownPeriod;
        boostMultipler = _boostMultipler;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        uint256 adjustedSupply = _totalSupply.sub(_supplyInCooldown);
        if (adjustedSupply == 0) {
            return rewardPerTokenStored;    
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(adjustedSupply)
            );
    }

    function rewardPerTokenWithDuration(uint256 duration) internal view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        uint256 adjustedSupply = _totalSupply.sub(_supplyInCooldown);
        if (adjustedSupply == 0) {
            return rewardPerTokenStored;    
        }
        return
            rewardPerTokenStored.add(
                duration.mul(rewardRate).mul(1e18).div(adjustedSupply)
            );
    }

    function earned(address account) public view returns (uint256) {
        LockData[] storage lock = lockedList[account];
        uint256 boosted = 0;
        // uint256 unboosted = 0;

        uint256 timeSinceLastUpdate = lastTimeRewardApplicable().sub(lastUpdateTime);

        uint256 lockPerToken = rewardPerTokenWithDuration(lockPeriod).sub(userRewardPerTokenPaid[account]).mul(boostMultipler);
        uint256 unboostedPerToken = rewardPerTokenWithDuration(timeSinceLastUpdate).sub(userRewardPerTokenPaid[account]);
        uint256 boostedPerToken = unboostedPerToken.mul(boostMultipler);

        uint256 unboostedRewards = 0;
        uint256 boostedRewards = 0;

        for (uint i = 0; i < lockedListLen[account]; i++) {
            LockData memory each = lock[i];
            // No reward for position in cooldown
            if (each.cooldownStartAt != 0) {
                continue;
            }
            if (each.locked == each.unlocked) {
                // unlocked & claimed position
                continue;
            }
            if (each.restaked) {
                // position restaked
                continue;
            }

            // position unlocked & not in cooldown 
            if (each.endAt < block.timestamp) {
                // uint256 passed = block.timestamp.sub(each.endAt);
                // uint256 eachPerToken = rewardPerTokenWithDuration(block.timestamp.sub(each.endAt)).sub(userRewardPerTokenPaid[account]);
                uint256 eachAmt = each.locked.sub(each.unlocked);
                unboostedRewards = unboostedRewards.add(eachAmt.mul(unboostedPerToken));
                boostedRewards = boostedRewards.add(eachAmt.mul(lockPerToken));
                // unboosted = unboosted.add(eachAmt);
            } else {
                // position is still locked
                boosted = boosted.add(each.locked);
            }
        }
        
        unboostedRewards = unboostedRewards.div(1e18);
        boostedRewards = boostedRewards.add(boosted.mul(boostedPerToken)).div(1e18);

        return unboostedRewards.add(boostedRewards).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);

        _balances[msg.sender] = _balances[msg.sender].add(amount);

        lockedList[msg.sender].push(LockData({
            startAt: block.timestamp,
            endAt: block.timestamp + lockPeriod,
            locked: amount,
            unlocked: 0,
            cooldownStartAt: 0,
            cooldownEndAt: 0,
            restaked: false
        }));
        
        lockedListLen[msg.sender] = lockedListLen[msg.sender].add(1);

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function restakeByIndex(uint256 index) external nonReentrant updateReward(msg.sender) {
        require(index < lockedListLen[msg.sender], "Index out of range");
    
        LockData storage lock = lockedList[msg.sender][index];

        require(block.timestamp >= lock.endAt, "position is still locked");
        require(!lock.restaked, "position already restaked");
        require(lock.cooldownStartAt == 0, "position is cooling down");

        lock.restaked = true;
        
        lockedList[msg.sender].push(LockData({
            startAt: block.timestamp,
            endAt: block.timestamp + lockPeriod,
            locked: lock.locked,
            unlocked: 0,
            cooldownStartAt: 0,
            cooldownEndAt: 0,
            restaked: false
        }));
        
        lockedListLen[msg.sender] = lockedListLen[msg.sender].add(1);

        emit Restaked(msg.sender, lock.locked);
    }

    function restakeAll() external nonReentrant updateReward(msg.sender) {
        LockData[] storage lock = lockedList[msg.sender];
        uint256 oldLength = lock.length;
        for (uint256 i = 0; i < oldLength; i++) {
            LockData memory each = lock[i];
            if (block.timestamp < each.endAt) {
                break;
            }
            if (each.restaked) {
                continue;
            }
            if (each.cooldownStartAt != 0) {
                continue;
            }
            lock[i].restaked = true;

            lockedList[msg.sender].push(LockData({
                startAt: block.timestamp,
                endAt: block.timestamp + lockPeriod,
                locked: each.locked,
                unlocked: 0,
                cooldownStartAt: 0,
                cooldownEndAt: 0,
                restaked: false
            }));

            lockedListLen[msg.sender] = lockedListLen[msg.sender].add(1);

            emit Restaked(msg.sender, each.locked);
        }
    }

    function startCooldownByIndex(uint256 index) public nonReentrant updateReward(msg.sender) {
        require(index < lockedListLen[msg.sender], "Index out of range");
    
        LockData storage lock = lockedList[msg.sender][index];
        
        require(block.timestamp >= lock.endAt, "still locked");
        require(!lock.restaked, "position restaked");
        require(lock.cooldownStartAt == 0, "already cooling down");

        lock.cooldownStartAt = block.timestamp;
        lock.cooldownEndAt = block.timestamp + cooldownPeriod;
        _balancesInCooldown[msg.sender] = _balancesInCooldown[msg.sender].add(lock.locked);
        _supplyInCooldown = _supplyInCooldown.add(lock.locked);

        emit PositionStartCooldown(msg.sender, index);
    }

    function startAllCooldown() public nonReentrant updateReward(msg.sender) {
        LockData[] storage lock = lockedList[msg.sender];

        for (uint256 i = 0; i < lock.length; i++) {
            LockData memory each = lock[i];
            if (block.timestamp < each.endAt) {
                break;
            }
            if (each.restaked) {
                continue;
            }
            if (each.cooldownStartAt != 0) {
                continue;
            }
            lock[i].cooldownStartAt = block.timestamp;
            lock[i].cooldownEndAt = block.timestamp + cooldownPeriod;
            _balancesInCooldown[msg.sender] = _balancesInCooldown[msg.sender].add(each.locked);
            _supplyInCooldown = _supplyInCooldown.add(each.locked);
            emit PositionStartCooldown(msg.sender, i);
        }
    }

    function withdrawAllUnlocked() public nonReentrant updateReward(msg.sender) {
    
        LockData[] storage lock = lockedList[msg.sender];
        uint256 totalUnlocked = 0;

        for (uint256 i = 0; i < lock.length; i++) {
            LockData memory each = lock[i];
            
            if (block.timestamp < each.endAt) {
                break;
            }

            if (each.restaked) {
                continue;
            }

            if (each.cooldownEndAt > block.timestamp) {
                // Still in cooldown / not started cooldown
                continue;
            }
            
            // Already withdrew
            if (each.unlocked == each.locked) {
                continue;
            }

            // No partially withdraw
            lock[i].unlocked = each.locked;
            totalUnlocked = totalUnlocked + each.locked;
        }

        require(totalUnlocked > 0, "nothing is unlocked");

        _totalSupply = _totalSupply.sub(totalUnlocked);
        _balances[msg.sender] = _balances[msg.sender].sub(totalUnlocked);
        _supplyInCooldown = _supplyInCooldown.sub(totalUnlocked);
        _balancesInCooldown[msg.sender] = _balancesInCooldown[msg.sender].sub(totalUnlocked);
        stakingToken.safeTransfer(msg.sender, totalUnlocked);
        emit Withdrawn(msg.sender, totalUnlocked);
    }

    function withdrawIndex(uint256 index) public nonReentrant updateReward(msg.sender) {

        require(index < lockedListLen[msg.sender], "Index out of range");
    
        LockData storage lock = lockedList[msg.sender][index];
        
        require(block.timestamp >= lock.endAt, "position is still locked");
        require(!lock.restaked, "position restaked");
        require(block.timestamp > lock.cooldownEndAt, "position is in cooldown");

        lock.unlocked = lock.locked;

        _totalSupply = _totalSupply.sub(lock.unlocked);
        _balances[msg.sender] = _balances[msg.sender].sub(lock.unlocked);
        _supplyInCooldown = _supplyInCooldown.sub(lock.unlocked);
        _balancesInCooldown[msg.sender] = _balancesInCooldown[msg.sender].sub(lock.unlocked);
        stakingToken.safeTransfer(msg.sender, lock.unlocked);
        emit Withdrawn(msg.sender, lock.unlocked);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdrawAllUnlocked();
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerTokenWithDuration(lastTimeRewardApplicable().sub(lastUpdateTime));
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Restaked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event PositionStartCooldown(address indexed user, uint256 index);
}
