import { subtask, task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { EneptiAccount, EneptiAccount__factory } from "../../typechain";

task("deploy:EneptiAccount").setAction(async (taskArgs, hre) => {
  await hre.run("deployEneptiAccount", {});
});

subtask("deployEneptiAccount").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const accountFactory: EneptiAccount__factory = await ethers.getContractFactory("EneptiAccount");
  const contract: EneptiAccount = <EneptiAccount>await accountFactory.deploy();
  await contract.deployed();
  console.log("EneptiAccount deployed to: ", contract.address);
  return contract;
});
