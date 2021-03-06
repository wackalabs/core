import { subtask, task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { RoomBase, RoomBase__factory } from "../../typechain";

task("deploy:RoomBase").setAction(async (taskArgs, hre) => {
  await hre.run("deployRoomBase", {});
});

subtask("deployRoomBase").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const roomBasefactory: RoomBase__factory = <RoomBase__factory>await ethers.getContractFactory("RoomBase");
  const roomBase: RoomBase = <RoomBase>await roomBasefactory.deploy();
  await roomBase.deployed();
  console.log("RoomBase deployed to: ", roomBase.address);
  return roomBase;
});
