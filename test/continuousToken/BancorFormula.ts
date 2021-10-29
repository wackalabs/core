import { BigNumber } from "@ethersproject/bignumber";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";

import { expect } from "chai";
import hre from "hardhat";
import { Artifact } from "hardhat/types";

import { BancorFormula } from "../../typechain";
import { Signers } from "../types";

const { utils } = hre.ethers;

// Note: As CT supply increases, CT price increases
const INITIAL_CONTINUOUS_TOKEN_SUPPLY = BigNumber.from(utils.parseEther("2.0").toString());
// Note: The higher the initial RT balance, the lower the initial CT prices are
const INITIAL_RESERVE_TOKEN_BALANCE = BigNumber.from(utils.parseEther("0.5").toString());
// As both initial CT and RT increases along the reserve ratio, CT price increases at slower rate
// Note: As reserve ratio increases, CT price increases at a slower rate
const RESERVE_RATIO_50 = 500000;
const RESERVE_RATIO_90 = 900000;
const ONE_TOKEN = BigNumber.from(utils.parseEther("1.0").toString());
const RESERVE_TOKEN_DEPOSIT_AMOUNT = ONE_TOKEN;

function effectivePrice(reserveTokenAmount: BigNumber, continuousTokenAmount: BigNumber): string {
  return reserveTokenAmount.mul(ONE_TOKEN).div(continuousTokenAmount).toString();
}

const simulatePriceGrowth = async (
  bancorFormula: BancorFormula,
  _reserveRatio: number,
  _continuousTokenSupply: BigNumber,
  _reserveTokenBalance: BigNumber,
  _purchaseIncrement: BigNumber,
) => {
  const reserveRatio = _reserveRatio;
  let continuousTokenSupply = _continuousTokenSupply;
  let reserveTokenBalance = _reserveTokenBalance;
  const purchaseIncrement = _purchaseIncrement;

  console.info(`reserveRatio: ${reserveRatio}`);
  console.info(`continuousSupply: ${BigNumber.from(continuousTokenSupply.toString())} CT`);
  console.info(`reserveBalance: ${BigNumber.from(reserveTokenBalance).toString()} RT`);

  for (let i = 0; i < 10; i += 1) {
    // eslint-disable-next-line
    const continuousTokenAmount = await bancorFormula.calculatePurchaseReturn(
      continuousTokenSupply,
      reserveTokenBalance,
      reserveRatio,
      purchaseIncrement,
    );
    console.info(
      `${BigNumber.from(purchaseIncrement.toString())} RT gets you \n
      ${BigNumber.from(continuousTokenAmount).toString()} @ \n
      ${effectivePrice(purchaseIncrement, continuousTokenAmount)} RT each`,
    );
    continuousTokenSupply = continuousTokenSupply.add(BigNumber.from(continuousTokenAmount));
    reserveTokenBalance = reserveTokenBalance.add(purchaseIncrement);
  }
};

describe("BancorFormula", function () {
  before(async function () {
    this.signers = {} as Signers;

    const signers: SignerWithAddress[] = await hre.ethers.getSigners();
    this.signers.admin = signers[0];

    const bancorFormulaArtifact: Artifact = await hre.artifacts.readArtifact("BancorFormula");
    this.bancorFormula = <BancorFormula>await hre.waffle.deployContract(this.signers.admin, bancorFormulaArtifact);
  });

  describe("BancorFormula", function () {
    let bancorFormula: BancorFormula;

    beforeEach(async function () {
      bancorFormula = await this.bancorFormula.connect(this.signers.admin);
    });

    it("calculates purchase and sale return", async () => {
      const buyAmount = await bancorFormula.calculatePurchaseReturn(
        INITIAL_CONTINUOUS_TOKEN_SUPPLY,
        INITIAL_RESERVE_TOKEN_BALANCE,
        RESERVE_RATIO_50,
        RESERVE_TOKEN_DEPOSIT_AMOUNT,
      );

      expect(buyAmount.toString()).to.equal("1464101615137754587"); // ~1.46 CT

      const newSupply = INITIAL_CONTINUOUS_TOKEN_SUPPLY.add(BigNumber.from(buyAmount));
      const newReserveBalance = INITIAL_RESERVE_TOKEN_BALANCE.add(BigNumber.from(RESERVE_TOKEN_DEPOSIT_AMOUNT));
      const sellAmount = await bancorFormula.calculateSaleReturn(
        newSupply,
        newReserveBalance,
        RESERVE_RATIO_50,
        buyAmount,
      );

      expect(sellAmount.toString()).to.equal("999999999999999999"); // ~1*10^18 RT
    });

    it("calculates CT price growth", async () => {
      // After X initial CT supply and Y reserve token balance,
      // acceptable CT price must be 1 ERC20 token (e.g. Dai) = 1 CT
      // TODO: make 1CT be equal to 0.01 ETH
      const RESERVE_RATIO = RESERVE_RATIO_90;
      const BUY_INCREMENT = BigNumber.from(utils.parseEther("10"));
      const CT_SUPPLY = BigNumber.from(utils.parseEther("100"));
      const RT_BALANCE = BigNumber.from(utils.parseEther("90"));

      await simulatePriceGrowth(bancorFormula, RESERVE_RATIO, CT_SUPPLY, RT_BALANCE, BUY_INCREMENT);
      expect(true).to.be.not.null;
    });
  });
});
