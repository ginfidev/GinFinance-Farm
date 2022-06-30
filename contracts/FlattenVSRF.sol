// File: access/Ownable.sol

pragma solidity ^0.5.16;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: libraries/Math.sol

pragma solidity ^0.5.16;

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: utils/ReentrancyGuard.sol

pragma solidity ^0.5.16;

contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

// File: libraries/SafeMath.sol

pragma solidity ^0.5.16;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: libraries/Address.sol

pragma solidity ^0.5.16;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: interfaces/IERC20.sol

pragma solidity ^0.5.16;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of intetokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: libraries/SafeERC20.sol

pragma solidity ^0.5.16;



library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: RewardLocker.sol

pragma solidity ^0.5.16;





contract RewardLocker is Ownable, ReentrancyGuard{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct VestingData {
    uint256 startTimestamp;
    uint256 endTimestamp;
    uint256 amount;
    uint256 vestedAmount;
  }

  IERC20 public rewardsToken;
  address public stakeAddr;
  uint256 public vestingDuration;
  uint256 public penaltyPercentage;
  uint256 public penaltyAmount = 0;

  address public penaltyOwner;
  
  mapping(address => uint256) public addrTotalVestingBal;
  mapping(address => uint256) public addrTotalVestedBal;
  mapping(address => VestingData[]) public vestingList;
  mapping(address => uint256) public vestListLen;

  modifier onlyStakeContract() {
    require(msg.sender == stakeAddr, "not stake contract");
    _;
  }

  modifier onlyPenaltyOwner() {
    require(msg.sender == penaltyOwner, "not penalty owner");
    _;
  }
  
  constructor(IERC20 _rewardsToken, address _owner, address _penaltyOwner, uint256 _vestingDuration) Ownable() public {
    rewardsToken = _rewardsToken;
    transferOwnership(_owner);
    stakeAddr = msg.sender;
    vestingDuration = _vestingDuration;
    uint256 hundred = 100;
    penaltyPercentage = hundred.div(20);
    penaltyOwner = _penaltyOwner;
  }

  function startVesting(address user, uint256 amount) external onlyStakeContract nonReentrant {
    require(amount > 0, "amount can not be 0");
    rewardsToken.safeTransferFrom(msg.sender, address(this), amount);

    uint256 vestingListLen = vestingList[user].length;
    uint256 startTime = block.timestamp;
    uint256 endTime = startTime.add(vestingDuration);

    if (vestingListLen > 0) {
      VestingData storage lastData = vestingList[user][vestingListLen.sub(1)];
      if (lastData.startTimestamp == startTime && lastData.endTimestamp == endTime) {
        lastData.amount = lastData.amount.add(amount);
        addrTotalVestingBal[user] = addrTotalVestingBal[user].add(amount);
        return;
      }
    }

    vestingList[user].push(VestingData({
      startTimestamp: startTime,
      endTimestamp: endTime,
      amount: amount,
      vestedAmount: 0
    }));

    addrTotalVestingBal[user] = addrTotalVestingBal[user].add(amount);
    
    vestListLen[user] = vestListLen[user].add(1);

    emit VestStarted(user, amount);
  }

  /**
   * @dev Allow a user to claim all the ended vesting
   */
  function claimAllEndedVesting() external nonReentrant {
    VestingData[] storage vest = vestingList[msg.sender];
    uint256 totalVesting = 0;

    for (uint256 i = 0; i < vest.length; i++) {
      VestingData memory eachVest = vest[i];
      if (block.timestamp < eachVest.endTimestamp) {
        break;
      }

      uint256 vestQuantity = eachVest.amount.sub(eachVest.vestedAmount);
      if (vestQuantity == 0) {
        continue;
      }

      vest[i].vestedAmount = eachVest.amount;
      totalVesting = totalVesting.add(vestQuantity);
    }

    if (totalVesting == 0) {
      return;
    }

    _completeVesting(msg.sender, totalVesting);
  }

  /**
   * @dev Allow a user to claim all the available vested reward
   */
  function claimAllVestedReward() external nonReentrant {
    VestingData[] storage vest = vestingList[msg.sender];
    uint256 totalVesting = 0;

    for (uint256 i = 0; i < vest.length; i++) {

      VestingData memory eachVest = vest[i];

      if (eachVest.amount == eachVest.vestedAmount) {
        continue;
      }

      uint256 vestQuantity = _getVestingQuantity(eachVest);
      
      if (vestQuantity == 0) {
        continue;
      }

      vest[i].vestedAmount = eachVest.vestedAmount.add(vestQuantity);

      totalVesting = totalVesting.add(vestQuantity);
    }

    if (totalVesting == 0) {
      return;
    }

    _completeVesting(msg.sender, totalVesting);
  }

  /**
   * @dev Allow a user to claim reward with penalty
   */
  function claimWithPenalty() external nonReentrant {
    VestingData[] storage vest = vestingList[msg.sender];
    uint256 totalVesting = 0;

    for (uint256 i = 0; i < vest.length; i++) {
      VestingData memory eachVest = vest[i];

      if (eachVest.amount == eachVest.vestedAmount) {
        continue;
      }

      // Add the unclaimed reward to total reward amount
      uint256 claimableAmount = _getVestingQuantity(eachVest);
      vest[i].vestedAmount = eachVest.vestedAmount.add(claimableAmount);
      totalVesting = totalVesting.add(claimableAmount);

      // Using the updated vested amount to calculate vest quantity
      uint256 vestQuantity = eachVest.amount.sub(vest[i].vestedAmount);
      if (vestQuantity == 0) {
        continue;
      }

      // 50% of the remaining reward

      uint256 remaining = eachVest.amount.sub(vest[i].vestedAmount);
      
      vestQuantity = remaining.div(penaltyPercentage);

      penaltyAmount = penaltyAmount.add(remaining.sub(vestQuantity));

      vest[i].vestedAmount = eachVest.amount;
      
      totalVesting = totalVesting.add(vestQuantity);
    }

    if (totalVesting == 0) {
      return;
    }

    _completeVesting(msg.sender, totalVesting);
  }

  function _completeVesting(address account, uint256 totalVesting) internal {
    addrTotalVestingBal[account] = addrTotalVestingBal[account].sub(totalVesting);
    addrTotalVestedBal[account] = addrTotalVestedBal[account].add(totalVesting);
    rewardsToken.safeTransfer(account, totalVesting);

    emit VestedRewardWithdrawn(account, totalVesting);
  }

  function _getVestingQuantity(VestingData memory vest) internal view returns (uint256) {

    if (block.timestamp >= vest.endTimestamp) {
      return vest.amount.sub(vest.vestedAmount);
    }

    if (block.timestamp <= vest.startTimestamp) {
      return 0;
    }
    uint256 lockDuration = vest.endTimestamp.sub(vest.startTimestamp);
    uint256 passedDuration = block.timestamp - vest.startTimestamp;
    return passedDuration.mul(vest.amount).div(lockDuration).sub(vest.vestedAmount);
  }

  function withdrawPenaltyLeftover(uint256 amount) external onlyPenaltyOwner {
    require(penaltyAmount > 0, "insufficient penalty amount");
    require(amount > 0, "can not withdraw 0");
    require(amount <= penaltyAmount, "insufficient penalty amount");
    require(amount <= rewardsToken.balanceOf(address(this)), "insufficient reward token balance");

    penaltyAmount = penaltyAmount.sub(amount);

    rewardsToken.safeTransfer(penaltyOwner, amount);

    emit LeftoverPenaltyWithdrawn(amount);
  }

  event VestStarted(address indexed addr, uint256 amount);
  event VestedRewardWithdrawn(address indexed addr, uint256 amount);
  event LeftoverPenaltyWithdrawn(uint256 amount);
}

// File: RewardsDistributionRecipient.sol

pragma solidity ^0.5.16;

contract RewardsDistributionRecipient {
    address public rewardsDistribution;

    function notifyRewardAmount(uint256 reward) external;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }
}

// File: interfaces/IStakingRewards.sol

pragma solidity ^0.5.16;

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}

// File: VestingStakingRewards.sol

pragma solidity ^0.5.16;









contract VestingStakingRewards is IStakingRewards, RewardsDistributionRecipient, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 30 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    RewardLocker public rewardLocker;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        address _penaltyOwner,
        uint256 _vestingPeriod,
        uint256 _rewardsDuration
    ) public {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        rewardsDuration = _rewardsDuration;
        rewardLocker = new RewardLocker(rewardsToken, msg.sender, _penaltyOwner, _vestingPeriod);
        rewardsToken.safeApprove(address(rewardLocker), uint(-1));
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
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            uint256 contractTokenBal = rewardsToken.balanceOf(address(this));
            if (reward > contractTokenBal) {
                reward = contractTokenBal;
            }
            rewards[msg.sender] = 0;
            rewardLocker.startVesting(msg.sender, reward);
            // rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardStartVest(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external onlyRewardsDistribution updateReward(address(0)) {

        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration.add(remaining));
        }

        lastUpdateTime = block.timestamp;

        if (block.timestamp >= periodFinish) {
            periodFinish = block.timestamp.add(rewardsDuration);
        } else {
            periodFinish = periodFinish.add(rewardsDuration);
        }

        emit RewardAdded(reward);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
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
    event Withdrawn(address indexed user, uint256 amount);
    event RewardStartVest(address indexed user, uint256 reward);
}

// File: VestingStakingRewardsFactory.sol

pragma solidity ^0.5.16;


contract VestingStakingRewardsFactory is Ownable {
    
    using SafeERC20 for IERC20;

    // immutables
    address public rewardsToken;
    uint public stakingRewardsGenesis;

    // info about rewards for a particular staking token
    struct StakingRewardsInfo {
        address stakingToken;
        address stakingRewards;
        uint256 rewardAmount;
        uint256 vestingPeriod;
        uint256 rewardDuration;
        uint256 deployAt;
    }

    StakingRewardsInfo[] public stakingRewardsInfoList;

    constructor(
        address _rewardsToken,
        uint _stakingRewardsGenesis
    ) Ownable() public {
        require(_stakingRewardsGenesis >= block.timestamp, 'VestingStakingRewardsFactory::constructor: genesis too soon');

        rewardsToken = _rewardsToken;
        stakingRewardsGenesis = _stakingRewardsGenesis;
    }

    ///// permissioned functions

    // deploy a staking reward contract for the staking token, and store the reward amount
    // the reward will be distributed to the staking reward contract no sooner than the genesis
    // vestPeriod takes the time as second, 1 day = 86400
    function deploy(address stakingToken, uint rewardAmount, uint256 vestPeriod, uint256 rewardDuration, address penaltyOwner) public onlyOwner {

        StakingRewardsInfo memory info;
        
        info.stakingRewards = address(new VestingStakingRewards(/*_rewardsDistribution=*/ address(this), rewardsToken, stakingToken, penaltyOwner, vestPeriod, rewardDuration));
        info.rewardAmount = rewardAmount;
        info.deployAt = block.timestamp;
        info.stakingToken = stakingToken;
        info.vestingPeriod = vestPeriod;
        info.rewardDuration = rewardDuration;

        stakingRewardsInfoList.push(info);

        emit PoolDeployed(stakingRewardsInfoList.length - 1, stakingToken, info.stakingRewards, penaltyOwner, rewardAmount, rewardDuration, vestPeriod);
    }

    ///// permissionless functions

    // call notifyRewardAmount for all staking tokens.
    function notifyRewardAmounts() public {
        require(stakingRewardsInfoList.length > 0, 'VestingStakingRewardsFactory::notifyRewardAmounts: called before any deploys');
        for (uint i = 0; i < stakingRewardsInfoList.length; i++) {
            notifyRewardAmount(i);
        }
    }

    // notify reward amount for an individual staking token.
    // this is a fallback in case the notifyRewardAmounts costs too much gas to call for all contracts
    function notifyRewardAmount(uint256 index) public {
        require(block.timestamp >= stakingRewardsGenesis, 'VestingStakingRewardsFactory::notifyRewardAmount: not ready');
        require(index < stakingRewardsInfoList.length, 'StakingRewardsFactory::notifyRewardAmount: index out of range');

        StakingRewardsInfo storage info = stakingRewardsInfoList[index];
        require(info.stakingRewards != address(0), 'VestingStakingRewardsFactoryFactory::notifyRewardAmount: not deployed');

        if (info.rewardAmount > 0) {
            uint rewardAmount = info.rewardAmount;
            info.rewardAmount = 0;

            IERC20(rewardsToken).safeTransfer(info.stakingRewards, rewardAmount);
            VestingStakingRewards(info.stakingRewards).notifyRewardAmount(rewardAmount);
            emit RewardNotified(index, rewardAmount);
        }
    }

    function extendStakingRewards(uint256 index, uint256 rewardAmount) external onlyOwner {
        require(block.timestamp >= stakingRewardsGenesis, 'VestingStakingRewardsFactory::extendStakingRewards: not ready');
        require(index < stakingRewardsInfoList.length, 'VestingStakingRewardsFactory::extendStakingRewards: incorrect index');
        require(rewardAmount > 0, 'VestingStakingRewardsFactory::extendStakingRewards: incorrect rewardAmount');

        StakingRewardsInfo storage info = stakingRewardsInfoList[index];
        require(info.stakingRewards != address(0), 'VestingStakingRewardsFactory::extendStakingRewards: not deployed');
        require(info.rewardAmount == 0, 'VestingStakingRewardsFactory::extendStakingRewards: not started');

        IERC20(rewardsToken).safeTransfer(info.stakingRewards, rewardAmount);
        VestingStakingRewards(info.stakingRewards).notifyRewardAmount(rewardAmount);
        emit PoolExtended(index, rewardAmount);
    }

    function stakingRewardsInfoListLength() external view returns (uint256) {
        return stakingRewardsInfoList.length;
    }

    event PoolDeployed(uint256 poolIndex, address stakingToken, address stakingReward, address penaltyOwner, uint256 rewardAmount, uint256 duration, uint256 vestingDuration);
    event PoolExtended(uint256 poolIndex, uint256 rewardAmount);
    event RewardNotified(uint256 poolIndex, uint256 rewardAmount);
}
