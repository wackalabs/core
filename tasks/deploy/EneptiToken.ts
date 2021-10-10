import { subtask, task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { EneptiToken, EneptiToken__factory } from "../../typechain";

task("deploy:EneptiToken").setAction(async (taskArgs, hre) => {
  await hre.run("deployEneptiToken", {});
});

subtask("deployEneptiToken").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const tokenFactory: EneptiToken__factory = <EneptiToken__factory>await ethers.getContractFactory("EneptiToken");
  const contract: EneptiToken = <EneptiToken>await tokenFactory.deploy();
  await contract.deployed();
  console.log("EneptiToken deployed to: ", contract.address);
  return contract;
});
