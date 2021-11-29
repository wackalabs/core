//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import "hardhat/console.sol";

import "../interfaces/ILazyERC721.sol";

contract LazyNFT is ILazyERC721, ERC721, ERC721URIStorage, EIP712, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    ERC20 public creatorToken;

    bool public gated;

    mapping(address => uint256) public pendingWithdrawals;

    constructor(
        address creator,
        address _creatorToken,
        string memory name,
        string memory symbol,
        string memory version,
        bool _gated
    ) ERC721(name, symbol) EIP712(name, version) {
        console.log("LazyERC721.sol: creator %s", creator);
        _setupRole(MINTER_ROLE, creator);
        creatorToken = ERC20(_creatorToken);
        gated = _gated;
    }

    /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
    /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
    /// @param redeemPrice price submitted by the redeemer in CreatorToken ERC20.
    function redeem(NFTVoucher calldata voucher, uint256 redeemPrice) external override returns (uint256) {
        // make sure signature is valid and get the address of the signer
        console.log(voucher.tokenId);
        console.log(voucher.minPrice);
        console.log(voucher.uri);
        console.logBytes(voucher.signature);
        address signer = _verify(voucher);

        console.log("LazyERC721.sol: signer %s", signer);

        // make sure that the signer is authorized to mint NFTs
        require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");

        // mak sure that the redeemer has enough balance of creator token to pay with
        require(creatorToken.balanceOf(msg.sender) >= redeemPrice, "Insuefficient balance to redeem");

        // make sure that the redeemer is paying enough to cover the buyer's cost
        require(redeemPrice >= voucher.minPrice, "Redeem price too low");

        // transfer redeem payment to the contract
        creatorToken.transferFrom(msg.sender, address(this), redeemPrice);

        // first assign the token to the signer, to establish provenance on-chain
        _mint(signer, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.uri);

        // transfer the token to the redeemer
        _transfer(signer, msg.sender, voucher.tokenId);

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

    /// @notice Retuns the amount of creator token balance available to the caller to withdraw.
    function availableToWithdraw() external view override returns (uint256) {
        return pendingWithdrawals[msg.sender];
    }

    /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An NFTVoucher to hash.
    function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("NFTVoucher(uint256 tokenId,uint256 minPrice,string uri)"),
                        voucher.tokenId,
                        voucher.minPrice,
                        keccak256(bytes(voucher.uri))
                    )
                )
            );
    }

    /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher An NFTVoucher describing an unminted NFT.
    function _verify(NFTVoucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    modifier onlyCreatorTokenHolders() {
        require(creatorToken.balanceOf(msg.sender) > 0, "Only creator token holders can access");
        _;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        if (gated) {
            return _getTokenURI(tokenId);
        } else {
            return super.tokenURI(tokenId);
        }
    }

    function _getTokenURI(uint256 tokenId) internal view virtual onlyCreatorTokenHolders returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }
}
