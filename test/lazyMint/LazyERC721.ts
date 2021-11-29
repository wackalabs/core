/* eslint-disable @typescript-eslint/no-unused-vars */
import { BigNumber } from "@ethersproject/bignumber";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";

import { expect } from "chai";
import hardhat from "hardhat";
import { ERC20, LazyERC721, LazyERC721__factory, TestERC20Token, TestERC20Token__factory } from "../../typechain";
import { Signers } from "../types";
import { Contract, utils } from "ethers";

const { ethers } = hardhat;

type NFTVoucher = {
  tokenId: BigNumber;
  uri: string;
  minPrice: BigNumber;
  signature: string;
};

const LOTS_OF_TOKENS = utils.parseEther("100");

/**
 * Creates a new NFTVoucher object and signs it using this LazyMinter's signing key.
 *
 * @param {ethers.BigNumber | number} tokenId the id of the un-minted NFT
 * @param {string} uri the metadata URI to associate with this NFT
 * @param {ethers.BigNumber | number} minPrice the minimum price (in wei) that
 *        the creator will accept to redeem this NFT. defaults to zero
 *
 * @returns {NFTVoucher}
 */
async function createVoucher(
  contract: Contract,
  signer: SignerWithAddress,
  tokenId: number,
  uri: string,
  minPrice: BigNumber = BigNumber.from(0),
): Promise<NFTVoucher> {
  const voucher = {
    tokenId: BigNumber.from(tokenId),
    uri,
    minPrice,
  };
  const domain = await signingDomain(contract);
  const types = {
    NFTVoucher: [
      { name: "tokenId", type: "uint256" },
      { name: "minPrice", type: "uint256" },
      { name: "uri", type: "string" },
    ],
  };
  const signature = await signer._signTypedData(domain, types, voucher);
  const verifiedAddress = ethers.utils.verifyTypedData(domain, types, voucher, signature);

  const nftVoucher = {
    ...voucher,
    signature,
  };
  // console.log("NFT voucher", JSON.stringify(nftVoucher, null, 2), signer.address, verifiedAddress);
  return nftVoucher;
}

// sign message broken in ethers@5.5.0.
// https://github.com/ethers-io/ethers.js/issues/1544
// Helper function to sign message
// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function signMessage(address: string, data: any) {
  return await hardhat.network.provider.send("eth_sign", [address, ethers.utils.hexlify(data)]);
}

/**
 * @returns {object} the EIP-721 signing domain, tied to the chainId of the signer
 */
async function signingDomain(contract: Contract) {
  const chainId = hardhat.network.config.chainId;
  const name = await contract.name();
  return {
    name,
    version: "1.0",
    verifyingContract: contract.address,
    chainId,
  };
}

async function deploy() {
  const [admin, user1, _] = await ethers.getSigners();

  const testERC20Factory: TestERC20Token__factory = <TestERC20Token__factory>(
    await ethers.getContractFactory("TestERC20Token", admin)
  );
  const creatorToken = await testERC20Factory.deploy("TestERC20Token", "TERC");
  await creatorToken.deployed();

  await creatorToken.mint(await admin.getAddress(), LOTS_OF_TOKENS);
  await creatorToken.mint(await user1.getAddress(), LOTS_OF_TOKENS);

  const factory: LazyERC721__factory = <LazyERC721__factory>await ethers.getContractFactory("LazyERC721", admin);
  const contract = await factory.deploy();
  await contract.deployed();

  await contract.initialize(await admin.getAddress(), creatorToken.address, "LazyERC721", "LAZY", "1.0", false);
  await creatorToken.approve(contract.address, LOTS_OF_TOKENS);

  const redeemerCreatorTokenFactory = testERC20Factory.connect(user1);
  const redeemerCreatorToken = redeemerCreatorTokenFactory.attach(creatorToken.address);
  await redeemerCreatorToken.approve(contract.address, LOTS_OF_TOKENS);

  // the redeemerContract is an instance of the contract that's wired up to the redeemer's signing key
  const redeemerFactory = factory.connect(user1);
  const redeemerContract = redeemerFactory.attach(contract.address);

  return {
    creatorToken,
    redeemerCreatorToken,
    minter: admin,
    redeemer: user1,
    contract,
    redeemerContract,
  };
}

describe("LazyERC721", function () {
  before(async function () {
    this.signers = {} as Signers;

    const signers: SignerWithAddress[] = await ethers.getSigners();
    this.signers.admin = signers[0];
    this.signers.user1 = signers[1];
  });

  describe("Deploy LazyERC721", function () {
    let contract: LazyERC721;
    let redeemerContract: LazyERC721;
    let redeemer: SignerWithAddress;
    let minter: SignerWithAddress;
    let voucher: NFTVoucher;
    let creatorToken: ERC20;
    let redeemerCreatorToken: ERC20;

    beforeEach(async function () {
      const {
        creatorToken: _creatorToken,
        redeemerCreatorToken: _redeemerCreatorToken,
        contract: _contract,
        redeemerContract: _redeemerContract,
        redeemer: _redeemer,
        minter: _minter,
      } = await deploy();
      contract = _contract;
      redeemerContract = _redeemerContract;
      redeemer = _redeemer;
      minter = _minter;
      creatorToken = _creatorToken;
      redeemerCreatorToken = _redeemerCreatorToken;
      voucher = await createVoucher(
        contract,
        minter,
        1,
        "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi",
      );
    });

    it("Should redeem an NFT from a signed voucher", async function () {
      await expect(redeemerContract.redeem(voucher, 0))
        .to.emit(contract, "Transfer") // transfer from null address to minter
        .withArgs("0x0000000000000000000000000000000000000000", minter.address, voucher.tokenId)
        .and.to.emit(contract, "Transfer") // transfer from minter to redeemer
        .withArgs(minter.address, redeemer.address, voucher.tokenId);
    });

    it("Should fail to redeem an NFT that's already been claimed", async function () {
      await expect(redeemerContract.redeem(voucher, 0))
        .to.emit(contract, "Transfer") // transfer from null address to minter
        .withArgs("0x0000000000000000000000000000000000000000", minter.address, voucher.tokenId)
        .and.to.emit(contract, "Transfer") // transfer from minter to redeemer
        .withArgs(minter.address, redeemer.address, voucher.tokenId);

      await expect(redeemerContract.redeem(voucher, 0)).to.be.revertedWith("ERC721: token already minted");
    });

    it("Should fail to redeem an NFT voucher that's signed by an unauthorized account", async function () {
      const signers = await ethers.getSigners();
      const rando = signers[signers.length - 1];
      const voucher = await createVoucher(
        contract,
        rando,
        1,
        "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi",
      );

      await expect(redeemerContract.redeem(voucher, 0)).to.be.revertedWith("Signature invalid or unauthorized");
    });

    it("Should fail to redeem an NFT voucher that's been modified", async function () {
      const signers = await ethers.getSigners();
      const rando = signers[signers.length - 1];
      const voucher = await createVoucher(
        contract,
        rando,
        1,
        "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi",
      );
      voucher.tokenId = BigNumber.from(2);
      await expect(redeemerContract.redeem(voucher, 0)).to.be.revertedWith("Signature invalid or unauthorized");
    });

    it("Should fail to redeem an NFT voucher with an invalid signature", async function () {
      const signers = await ethers.getSigners();
      const rando = signers[signers.length - 1];
      const voucher = await createVoucher(
        contract,
        rando,
        1,
        "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi",
      );

      const dummyData = ethers.utils.randomBytes(128);
      voucher.signature = await signMessage(await redeemer.getAddress(), dummyData);

      await expect(redeemerContract.redeem(voucher, 0)).to.be.revertedWith("Signature invalid or unauthorized");
    });

    it("Should redeem if payment is >= minPrice", async function () {
      const minPrice = ethers.constants.WeiPerEther.div(BigInt(3)); // charge 0.3 Eth
      const voucher = await createVoucher(
        contract,
        minter,
        1,
        "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi",
        minPrice,
      );

      await expect(redeemerContract.redeem(voucher, minPrice))
        .to.emit(contract, "Transfer") // transfer from null address to minter
        .withArgs("0x0000000000000000000000000000000000000000", minter.address, voucher.tokenId)
        .and.to.emit(contract, "Transfer") // transfer from minter to redeemer
        .withArgs(minter.address, redeemer.address, voucher.tokenId);
    });

    it("Should fail to redeem if payment is < minPrice", async function () {
      const minPrice = ethers.constants.WeiPerEther.div(BigInt(3)); // charge 0.3 Eth
      const voucher = await createVoucher(
        contract,
        minter,
        1,
        "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi",
        minPrice,
      );

      const payment = minPrice.sub(10000);
      await expect(redeemerContract.redeem(voucher, payment)).to.be.revertedWith("Redeem price too low");
    });

    it("Should make payments available to minter for withdrawal", async function () {
      const minPrice = ethers.constants.WeiPerEther.div(BigInt(3)); // charge 0.3 Eth
      const voucher = await createVoucher(
        contract,
        minter,
        1,
        "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi",
        minPrice,
      );

      // the payment should be sent from the redeemer's account to the contract address
      await expect(() => redeemerContract.redeem(voucher, minPrice)).to.changeTokenBalance(
        redeemerCreatorToken,
        redeemer,
        minPrice.mul(-1).toString(),
      );

      // minter should have funds available to withdraw
      await expect(await contract.availableToWithdraw()).to.equal(minPrice.toString());

      // withdrawal should increase minter's balance
      await expect(() => contract.withdraw()).to.changeTokenBalance(creatorToken, minter, minPrice.toString());

      // minter should now have zero available
      await expect(await contract.availableToWithdraw()).to.equal(0);
    });
  });
});
