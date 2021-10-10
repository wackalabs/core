import { subtask, task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { SocialToken, SocialToken__factory } from "../../typechain";

task("deploy:SocialToken")
  .addParam("lmnToken", "lmn_token_address")
  .addParam("name", "token_name")
  .addParam("symbol", "token_symbol")
  .addParam("creator", "creator_address")
  .setAction(async (taskArguments: TaskArguments, hre) => {
    await hre.run("deploySocialToken", {
      lmnToken: taskArguments.lmnToken,
      name: taskArguments.name,
      symbol: taskArguments.symbol,
      creator: taskArguments.creator,
    });
  });

subtask("deploySocialToken")
  .addParam("lmnToken", "lmn_token_address")
  .addParam("name", "token_name")
  .addParam("symbol", "token_symbol")
  .addParam("creator", "creator_address")
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    const socialTokenFactory: SocialToken__factory = <SocialToken__factory>(
      await ethers.getContractFactory("SocialToken")
    );
    const socialToken: SocialToken = <SocialToken>(
      await socialTokenFactory.deploy(
        taskArguments.lmnToken,
        taskArguments.name,
        taskArguments.symbol,
        taskArguments.creator,
      )
    );
    await socialToken.deployed();
    console.log("SocialToken deployed to: ", socialToken.address);
    return socialToken;
  });
