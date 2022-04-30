const { ethers, deployments } = require("hardhat");
const { moveBlocks } = require("../utills/move_block");
const { moveTime } = require("../utills/move_time");

const SECONDS_IN_A_DAY = 86400;

describe("Staking Test", async () => {
  let staking, rewardToken, deployer, dai, stakeAmount;

  beforeEach(async function () {
    const accounts = await ethers.getSigners();
    deployer = accounts[0];
    await deployments.fixture(["all"]);
    rewardToken = await ethers.getContract("RewardToken");
    staking = await ethers.getContract("Staking");
    stakeAmount = ethers.utils.parseEther("100000");
  });

  describe("stake", () => {
    it("Allows users to stake and claim rewards", async () => {
      await rewardToken.approve(staking.address, stakeAmount);
      await staking.stake(stakeAmount);
      const startingEarned = await staking.earned(deployer.address);
      console.log(`Starting Earned ${startingEarned}`);

      await moveTime(SECONDS_IN_A_DAY);
      await moveBlocks(1);
      const endingEarned = await staking.earned(deployer.address);
      console.log(`Ending Earned ${endingEarned}`);
    });
  });
});
