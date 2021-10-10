import { subtask, task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { InitializedProxy, InitializedProxy__factory } from "../../typechain";

task("deploy:InitializedProxy")
  .addParam("logic", "logic contract address")
  .addParam("initializationCalldata", "initialization calldata")
  .setAction(async (taskArgs, hre) => {
    await hre.run("deployInitializedProxy", {
      logic: taskArgs.logic,
      initializationCalldata: taskArgs.initializationCalldata,
    });
  });

subtask("deployInitializedProxy")
  .addParam("logic", "logic contract address")
  .addParam("initializationCalldata", "initialization calldata")
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    const factory: InitializedProxy__factory = <InitializedProxy__factory>(
      await ethers.getContractFactory("InitializedProxy")
    );
    const contract: InitializedProxy = <InitializedProxy>(
      await factory.deploy(taskArguments.logic, taskArguments.initializationCalldata)
    );
    await contract.deployed();
    console.log("InitializedProxy deployed to: ", contract.address);
    return contract;
  });
