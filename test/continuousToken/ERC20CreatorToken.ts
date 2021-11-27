import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";

import { expect } from "chai";
import hre from "hardhat";
import { Artifact } from "hardhat/types";

import { ERC20CreatorToken, TestERC20Token } from "../../typechain";
import { Signers } from "../types";

const { utils } = hre.ethers;

const ONE_TOKEN = utils.parseEther("1");
const LOTS_OF_TOKENS = utils.parseEther("100");
const INITIAL_SUPPLY = ONE_TOKEN;
const INITIAL_RESERVE = ONE_TOKEN;
const RESERVE_RATIO = 500000; // 1/2 reserve ratio

describe("ERC20CreatorToken", function () {
  before(async function () {
    this.signers = {} as Signers;
    const signers: SignerWithAddress[] = await hre.ethers.getSigners();
    this.signers.admin = signers[0];
    this.signers.user1 = signers[1];
  });

  describe("ERC20CreatorToken", function () {
    let reserveToken: TestERC20Token;
    let erc20CreatorToken: ERC20CreatorToken;
    let creator: SignerWithAddress;
    let user: SignerWithAddress;

    beforeEach(async function () {
      const testERC20Artifact: Artifact = await hre.artifacts.readArtifact("TestERC20Token");
      reserveToken = <TestERC20Token>(
        await hre.waffle.deployContract(this.signers.admin, testERC20Artifact, ["TestERC20Token", "TERC"])
      );

      creator = this.signers.admin;
      const creatorAddress = await creator.getAddress();
      user = this.signers.user1;
      const userAddress = await user.getAddress();

      await reserveToken.mint(creatorAddress, LOTS_OF_TOKENS);

      const tokenArtifact: Artifact = await hre.artifacts.readArtifact("ERC20CreatorToken");
      erc20CreatorToken = <ERC20CreatorToken>(
        await hre.waffle.deployContract(this.signers.admin, tokenArtifact, [reserveToken.address, RESERVE_RATIO])
      );
      await erc20CreatorToken.initialize(creatorAddress, INITIAL_SUPPLY, "Gyld Token", "GYL");

      // Mint reserve tokens to CT
      await reserveToken.transfer(erc20CreatorToken.address, INITIAL_RESERVE, { from: creatorAddress });

      // User reserve token balances
      await reserveToken.mint(userAddress, LOTS_OF_TOKENS);
    });

    it("initialized correctly", async () => {
      const tokenOwner = await erc20CreatorToken.owner();
      expect(tokenOwner).to.equal(await creator.getAddress());

      const totalSupply = await erc20CreatorToken.totalSupply();
      expect(totalSupply).to.equal(INITIAL_SUPPLY);

      const reserveRatio = await erc20CreatorToken.reserveRatio();
      expect(reserveRatio).to.equal(RESERVE_RATIO);

      const reserveBalance = await erc20CreatorToken.reserveBalance();
      expect(reserveBalance).to.equal(ONE_TOKEN);
    });

    it("should mint continuous tokens when given reserve tokens", async () => {
      const userAddress = await user.getAddress();
      const oldBalance = await erc20CreatorToken.balanceOf(userAddress);
      expect(oldBalance.toString()).to.equal("0");

      const depositAmount = ONE_TOKEN;
      const rewardAmount = await erc20CreatorToken.getContinuousMintReward(depositAmount);
      expect(rewardAmount.toString()).to.equal("414213562373095048"); // 0.4 CT

      await reserveToken.connect(user).approve(erc20CreatorToken.address, depositAmount);

      await expect(erc20CreatorToken.connect(user).mint(depositAmount))
        .to.emit(erc20CreatorToken, "Minted")
        .withArgs(userAddress, rewardAmount, depositAmount);

      const reserveBalance = await erc20CreatorToken.reserveBalance();
      expect(reserveBalance.toString()).to.equal(utils.parseEther("2").toString()); // 2 RT

      const newBalance = await erc20CreatorToken.balanceOf(userAddress);
      expect(newBalance.toString(), rewardAmount.toString());
    });

    it("should refund reserve tokens when burned", async () => {
      const userAddress = await user.getAddress();

      const depositAmount = ONE_TOKEN;
      await reserveToken.connect(user).approve(erc20CreatorToken.address, depositAmount);

      await erc20CreatorToken.connect(user).mint(depositAmount);

      const oldBalance = await erc20CreatorToken.balanceOf(userAddress);
      expect(oldBalance.toString(), "414213562373095048"); // 0.4 CT

      const burnAmount = oldBalance;
      const refundAmount = await erc20CreatorToken.getContinuousBurnRefund(burnAmount);

      expect(refundAmount.toString(), "999999999999999998"); // ~1 RT

      await expect(erc20CreatorToken.connect(user).burn(burnAmount))
        .to.emit(erc20CreatorToken, "Burned")
        .withArgs(userAddress, burnAmount, refundAmount);

      const newBalance = await erc20CreatorToken.balanceOf(userAddress);
      expect(newBalance.toString(), "0");

      const reserveBalance = await erc20CreatorToken.reserveBalance();
      expect(reserveBalance.toString(), "1000000000000000002"); // 2 - 0.9999 = ~1 RT
    });
  });
});
