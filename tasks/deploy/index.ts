import "./AccountRegistry";
import "./BancorFormula";
import "./EneptiAccount";
import "./EneptiToken";
import "./LMNToken";
import "./SocialToken";
import "./RoomBase";
import { task } from "hardhat/config";
import { EneptiAccount, EneptiToken, LMNToken } from "../../typechain";

function sleep(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    const balance = await account.getBalance();
    console.log(account.address, balance.toString());
  }
});

task("deploy", "Deploy all contracts", async (taskArgs, hre) => {
  // contracts are not deployed in parallel. You can send 1 transaction on ethereum at a time.
  await hre.run("deployBancorFormula", {});
  await sleep(1000);

  const eneptiAccount = await hre.run("deployEneptiAccount", {});
  await sleep(1000);

  const eneptiToken = await hre.run("deployEneptiToken", {});
  await sleep(1000);

  const lmnToken = await hre.run("deployLMNToken", {});
  await sleep(1000);

  await hre.run("deployRoomBase", {});
  await sleep(1000);

  const accounts = await hre.ethers.getSigners();

  await hre.run("deployAccountRegistry", {
    accountAddress: (eneptiAccount as EneptiAccount).address,
    tokenAddress: (eneptiToken as EneptiToken).address,
  });
  await sleep(1000);

  await hre.run("deploySocialToken", {
    lmnToken: (lmnToken as LMNToken).address,
    name: "token_name",
    symbol: "token_symbol",
    creator: accounts[1].address,
  });
  await sleep(1000);
});
