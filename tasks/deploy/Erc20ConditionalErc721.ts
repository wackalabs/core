import { BigNumber } from "@ethersproject/bignumber";
import { utils } from "ethers";
import { subtask, task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { Erc20ConditionalErc721, Erc20ConditionalErc721__factory } from "../../typechain";

task("deploy:Erc20ConditionalErc721")
  .addParam("conditionERC20", "conditionERC20")
  .addParam("conditionBalance", "conditionBalance")
  .addParam("name", "name")
  .addParam("symbol", "symbol")
  .setAction(async (taskArgs, hre) => {
    await hre.run("deployErc20ConditionalErc721", { ...taskArgs });
  });

subtask("deployErc20ConditionalErc721")
  .addParam("conditionERC20", "conditionERC20")
  .addParam("conditionBalance", "conditionBalance")
  .addParam("name", "name")
  .addParam("symbol", "symbol")
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    const factory: Erc20ConditionalErc721__factory = <Erc20ConditionalErc721__factory>(
      await ethers.getContractFactory("Erc20ConditionalErc721")
    );
    const contract: Erc20ConditionalErc721 = <Erc20ConditionalErc721>(
      await factory.deploy(
        taskArguments.conditionERC20,
        BigNumber.from(utils.parseEther(taskArguments.conditionBalance).toString()),
        taskArguments.name,
        taskArguments.symbol,
      )
    );
    await contract.deployed();
    console.log("Erc20ConditionalErc721 deployed to: ", contract.address);
    return contract;
  });
