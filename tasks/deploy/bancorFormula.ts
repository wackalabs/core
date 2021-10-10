import { subtask, task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { BancorFormula, BancorFormula__factory } from "../../typechain";

task("deploy:BancorFormula").setAction(async (taskArgs, hre) => {
  await hre.run("deployBancorFormula", {});
});

subtask("deployBancorFormula").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const bancorFormulafactory: BancorFormula__factory = <BancorFormula__factory>(
    await ethers.getContractFactory("BancorFormula")
  );
  const bancorFormula: BancorFormula = <BancorFormula>await bancorFormulafactory.deploy();
  await bancorFormula.deployed();
  console.log("BancorFormula deployed to: ", bancorFormula.address);
  return bancorFormula;
});
