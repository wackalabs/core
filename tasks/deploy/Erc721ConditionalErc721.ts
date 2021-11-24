import { subtask, task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { Erc721ConditionalErc721, Erc721ConditionalErc721__factory } from "../../typechain";

task("deploy:Erc721ConditionalErc721")
  .addParam("conditionNFT", "conditionNFT")
  .addParam("name", "name")
  .addParam("symbol", "symbol")
  .setAction(async (taskArgs, hre) => {
    await hre.run("deployErc721ConditionalErc721", { ...taskArgs });
  });

subtask("deployErc721ConditionalErc721")
  .addParam("conditionNFT", "conditionNFT")
  .addParam("name", "name")
  .addParam("symbol", "symbol")
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    const factory: Erc721ConditionalErc721__factory = <Erc721ConditionalErc721__factory>(
      await ethers.getContractFactory("Erc721ConditionalErc721")
    );
    const contract: Erc721ConditionalErc721 = <Erc721ConditionalErc721>(
      await factory.deploy(taskArguments.conditionNFT, taskArguments.name, taskArguments.symbol)
    );
    await contract.deployed();
    console.log("Erc721ConditionalErc721 deployed to: ", contract.address);
    return contract;
  });
