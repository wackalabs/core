import { subtask, task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { ERC721VaultFactory, ERC721VaultFactory__factory } from "../../typechain";

task("deploy:ERC721VaultFactory")
  .addParam("settings", "settings contract address")
  .setAction(async (taskArgs, hre) => {
    await hre.run("deployERC721VaultFactory", { settings: taskArgs.settings });
  });

subtask("deployERC721VaultFactory")
  .addParam("settings", "settings contract address")
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    const factory: ERC721VaultFactory__factory = <ERC721VaultFactory__factory>(
      await ethers.getContractFactory("ERC721VaultFactory")
    );
    const contract: ERC721VaultFactory = <ERC721VaultFactory>await factory.deploy(taskArguments.settings);
    await contract.deployed();
    console.log("ERC721VaultFactory deployed to: ", contract.address);
    return contract;
  });
