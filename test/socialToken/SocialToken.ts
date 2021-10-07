import hre from "hardhat";
import { Artifact } from "hardhat/types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";

import { LMNToken, SocialToken } from "../../typechain";
import { Signers } from "../types";
import { shouldBehaveLikeSocialToken } from "./SocialToken.behavior";

const { deployContract } = hre.waffle;

describe("Unit tests", function () {
  before(async function () {
    this.signers = {} as Signers;

    const signers: SignerWithAddress[] = await hre.ethers.getSigners();
    this.signers.admin = signers[0];
  });

  describe("SocialToken", function () {
    beforeEach(async function () {
      const lmnTokenArtifact: Artifact = await hre.artifacts.readArtifact("LMNToken");
      this.lmnToken = <LMNToken>await deployContract(this.signers.admin, lmnTokenArtifact);

      const socialTokenArtifact: Artifact = await hre.artifacts.readArtifact("SocialToken");
      this.socialToken = <SocialToken>(
        await deployContract(this.signers.admin, socialTokenArtifact, [
          "0x7be8076f4ea4a4ad08075c2508e481d6c946d12b",
          "token_name",
          "token_symbol",
          this.signers.admin.getAddress(),
        ])
      );
    });

    shouldBehaveLikeSocialToken();
  });
});
