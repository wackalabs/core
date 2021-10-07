import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { BancorFormula, BancorFormula__factory } from "../../typechain";

task("deploy:BancorFormula").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const bancorFormulafactory: BancorFormula__factory = await ethers.getContractFactory("BancorFormula");
  const bancorFormula: BancorFormula = <BancorFormula>await bancorFormulafactory.deploy();
  await bancorFormula.deployed();
  console.log("BancorFormula deployed to: ", bancorFormula.address);
});
