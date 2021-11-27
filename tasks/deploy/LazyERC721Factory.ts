import { subtask, task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { LazyERC721Factory, LazyERC721Factory__factory } from "../../typechain";

task("deploy:LazyERC721Factory").setAction(async (taskArgs, hre) => {
  await hre.run("deployLazyERC721Factory", { settings: taskArgs.settings });
});

subtask("deployLazyERC721Factory").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const factory: LazyERC721Factory__factory = <LazyERC721Factory__factory>(
    await ethers.getContractFactory("LazyERC721Factory")
  );
  const contract: LazyERC721Factory = <LazyERC721Factory>await factory.deploy();
  await contract.deployed();
  console.log("LazyERC721Factory deployed to: ", contract.address);
  return contract;
});
