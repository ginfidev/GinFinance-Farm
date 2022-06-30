const StakeFactory = artifacts.require("GinLockedStakingRewardsFactory")
const ERC20 = artifacts.require("interfaces/IERC20")

const GINAddress = "0xce407B8Bc78274E6338E7a1eB4C9F4c4374bFAcf"
const rewardAmount = 86400 * 1e18
const rewardDuration = 86400 // 1 day

const lockPeriod = 600 // 10mins
const cooldownPeriod = 600
const boostMultipler = 2

const getNow = () => Math.floor(new Date().getTime() / 1000)
const toBigStr = num => num.toLocaleString().replaceAll(",", "")
const wait = ms => new Promise(resolve => setTimeout(resolve, ms))

const rewardInBig = toBigStr(rewardAmount)

module.exports = async function(deployer) {
  const GINToken = await ERC20.at(GINAddress)
  

  await deployer.deploy(StakeFactory, GINAddress);
  
  const instance = await StakeFactory.deployed()

  const r = await instance.deploy(
    GINAddress,
    rewardInBig,
    rewardDuration,
    lockPeriod,
    cooldownPeriod,
    boostMultipler
  )

  console.log(r)

  const info = await instance.stakingRewardsInfoList(0)

  console.log("Factory: ", instance.address)
  console.log("Staking Rewards: ", info.stakingRewards)

  await GINToken.transfer(instance.address, toBigStr(rewardAmount * 3))

  await wait(3000)

  await instance.notifyRewardAmounts()

  console.log("Farm Started")
};  