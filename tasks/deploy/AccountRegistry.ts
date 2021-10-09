import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { AccountRegistry, AccountRegistry__factory } from "../../typechain";

task("deploy:AccountRegistry")
  .addParam("accountAddress", "Enepti Account address")
  .addParam("tokenAddress", "EneptiToken address")
  .setAction(async (taskArgs, hre) => {
    await hre.run("deployAccountRegistry", {
      accountAddress: taskArgs.accountAddress,
      tokenAddress: taskArgs.tokenAddress,
    });
  });

task("deployAccountRegistry")
  .addParam("accountAddress", "account_address")
  .addParam("tokenAddress", "token_name")
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    const registryFactory: AccountRegistry__factory = await ethers.getContractFactory("AccountRegistry");
    const contract: AccountRegistry = <AccountRegistry>(
      await registryFactory.deploy(taskArguments.accountAddress, taskArguments.tokenAddress)
    );
    await contract.deployed();
    console.log("AccountRegistry deployed to: ", contract.address);
    return contract;
  });
