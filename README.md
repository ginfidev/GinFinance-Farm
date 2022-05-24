# Farm

```
function balanceOf(address account) external view returns (uint256)
```

Get target address staked amount

---

```
function totalSupply() external view returns (uint256)
```

Get total staked amount

---


```
function earned(address account) public view returns (uint256)
```

Get how much reward the target address can claim now


---

```
function stake(uint256 amount) external;
```

Stake amount token (in wei)

---

```
function withdraw(uint256 amount) external;
```
Withdraw the amount of staking token (in wei)

---

```
function getReward() external;
```

Claim all available rewards

---

```
function exit() external;
```

Claim All reward & withdraw all staking token

---

# Vesting Farm

```
function getReward() external;
```

Start vesting all available rewards

---

```
function exit() external;
```

Start vesting all available rewards & withdraw all staked token

---

```
function claimAllEndedVesting() external;
```

Claim all done vesting reward

---

```
function claimAllVestedReward() external;
```

Claim all vested reward

---

```
function claimWithPenalty() external;
```

claim reward instantly with 50% penalty

# Reward Locker

# GinFinance-Farm
