import { subtask, task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { LMNToken, LMNToken__factory } from "../../typechain";

task("deploy:LMNToken").setAction(async (taskArgs, hre) => {
  await hre.run("deployLMNToken", {});
});

subtask("deployLMNToken").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const lmnTokenFactory: LMNToken__factory = await ethers.getContractFactory("LMNToken");
  const lmnToken: LMNToken = <LMNToken>await lmnTokenFactory.deploy();
  await lmnToken.deployed();
  console.log("LMNToken deployed to: ", lmnToken.address);
  return lmnToken;
});
