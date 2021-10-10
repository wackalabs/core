import { subtask, task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { Settings, Settings__factory } from "../../typechain";

task("deploy:Settings").setAction(async (taskArgs, hre) => {
  await hre.run("deploySettings", {});
});

subtask("deploySettings").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const factory: Settings__factory = <Settings__factory>await ethers.getContractFactory("Settings");
  const contract: Settings = <Settings>await factory.deploy();
  await contract.deployed();
  console.log("Settings deployed to: ", contract.address);
  return contract;
});
