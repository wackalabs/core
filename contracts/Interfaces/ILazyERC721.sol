//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface ILazyERC721 {
    /// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain.
    /// A signed voucher can be redeemed for a real NFT using the redeem function.
    struct NFTVoucher {
        /// @notice The id of the token to be redeemed. Must be unique.
        /// if another token with this ID already exists, the redeem function will revert.
        uint256 tokenId;
        /// @notice The minimum price (in wei) that the NFT creator is willing to accept for the initial sale of this NFT.
        uint256 minPrice;
        /// @notice The address of the creator token that redeemers can mint the NFT with.
        ERC20 creatorToken;
        /// @notice The metadata URI to associate with this token.
        string uri;
        /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct.
        /// For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
        bytes signature;
    }

    /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
    /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
    /// @param redeemPrice price submitted by the redeemer in CreatorToken ERC20.
    function redeem(NFTVoucher calldata voucher, uint256 redeemPrice) external returns (uint256);

    /// @notice Transfers all pending withdrawal balance to the caller. Reverts if the caller is not an authorized minter.
    function withdraw() external;

    /// @notice Retuns the amount of Ether available to the caller to withdraw.
    function availableToWithdraw() external view returns (uint256);
}
