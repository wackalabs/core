//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import "./LazyERC721.sol";

contract LazyEthNFT is LazyERC721 {
    ERC20 public creatorToken;

    constructor(
        string memory name,
        string memory symbol,
        string memory version,
        ERC20 _creatorToken
    ) LazyERC721(payable(msg.sender), name, symbol, version) {
        creatorToken = _creatorToken;
    }

    /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
    /// @param redeemer The address of the account which will receive the NFT upon success.
    /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
    /// @param redeemPrice price submitted by the redeemer in CreatorToken ERC20.
    function redeem(
        address redeemer,
        NFTVoucher calldata voucher,
        uint256 redeemPrice
    ) external payable override returns (uint256) {
        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);

        // make sure that the signer is authorized to mint NFTs
        require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");

        // make sure that the redeemer has enough balance of creator token to pay with
        require(creatorToken.balanceOf(msg.sender) >= redeemPrice, "Insufficient balance to redeem");

        // make sure that the redeemer is paying enough to cover the buyer's cost
        require(redeemPrice >= voucher.minPrice, "Redeem price too low");

        // transfer redeem payment to the contract
        creatorToken.transferFrom(msg.sender, address(this), redeemPrice);

        // first assign the token to the signer, to establish provenance on-chain
        _mint(signer, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.uri);

        // transfer the token to the redeemer
        _transfer(signer, redeemer, voucher.tokenId);

        // record payment to signer's withdrawal balance
        pendingWithdrawals[signer] += redeemPrice;

        return voucher.tokenId;
    }

    /// @notice Transfers all pending withdrawal balance to the caller. Reverts if the caller is not an authorized minter.
    function withdraw() public override {
        require(hasRole(MINTER_ROLE, msg.sender), "Only authorized minters can withdraw");

        uint256 amount = pendingWithdrawals[msg.sender];
        // zero account before transfer to prevent re-entrancy attack
        pendingWithdrawals[msg.sender] = 0;
        creatorToken.transferFrom(address(this), msg.sender, amount);
    }
}
