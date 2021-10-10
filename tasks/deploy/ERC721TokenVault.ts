import { subtask, task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { TokenVault, TokenVault__factory } from "../../typechain";

task("deploy:ERC721TokenVault")
  .addParam("settings", "settings contract address")
  .setAction(async (taskArgs, hre) => {
    await hre.run("deployERC721TokenVault", { settings: taskArgs.settings });
  });

subtask("deployERC721TokenVault")
  .addParam("settings", "settings contract address")
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    const factory: TokenVault__factory = <TokenVault__factory>await ethers.getContractFactory("ERC721TokenVault");
    const contract: TokenVault = <TokenVault>await factory.deploy(taskArguments.settings);
    await contract.deployed();
    console.log("ERC721TokenVault deployed to: ", contract.address);
    return contract;
  });
