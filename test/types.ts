import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { Fixture } from "ethereum-waffle";

import { SocialToken, BancorFormula, ERC20CreatorToken, ERC20CreatorTokenFactory, LazyERC721 } from "../typechain";

declare module "mocha" {
  export interface Context {
    socialToken: SocialToken;
    bancorFormula: BancorFormula;
    erc20CreatorToken: ERC20CreatorToken;
    lazyERC721: LazyERC721;
    factory: ERC20CreatorTokenFactory;
    loadFixture: <T>(fixture: Fixture<T>) => Promise<T>;
    signers: Signers;
  }
}

export interface Signers {
  admin: SignerWithAddress;
  user1: SignerWithAddress;
}
