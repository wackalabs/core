//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

// import "hardhat/console.sol";

contract RealmERC721 is ERC721Upgradeable, ERC721URIStorageUpgradeable, EIP712Upgradeable, AccessControlUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bool public gated;

    /// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain.
    /// A signed voucher can be redeemed for a real NFT using the redeem function.
    struct NFTVoucher {
        /// @notice The id of the token to be redeemed. Must be unique.
        /// if another token with this ID already exists, the redeem function will revert.
        uint256 tokenId;
        /// @notice The minimum price (in wei) that the NFT creator is willing to accept for the initial sale of this NFT.
        uint256 minPrice;
        /// @notice The metadata URI to associate with this token.
        string uri;
        /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct.
        /// For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
        bytes signature;
    }

    function initialize(
        address creator,
        string memory name,
        string memory symbol,
        string memory version,
        bool _gated
    ) external initializer {
        // initialize inherited contracts
        __ERC721_init(name, symbol);
        __ERC721URIStorage_init();
        __AccessControl_init();
        __EIP712_init(name, version);

        // console.log("LazyERC721.sol: creator %s", creator);
        _setupRole(MINTER_ROLE, creator);
        gated = _gated;
    }

    /// @notice Redeems an NFTVoucher for an actual NFT, creating it in the process.
    /// @param voucher A signed NFTVoucher that describes the NFT to be redeemed.
    function redeem(NFTVoucher calldata voucher) external payable returns (uint256) {
        // make sure signature is valid and get the address of the signer
        // console.log(voucher.tokenId);
        // console.log(voucher.minPrice);
        // console.log(voucher.uri);
        // console.logBytes(voucher.signature);
        // console.log("redeemPrice %s %s %s", redeemPrice, msg.sender, creatorToken.balanceOf(msg.sender));
        address signer = _verify(voucher);

        // console.log("LazyERC721.sol: signer %s", signer);

        // make sure that the signer is authorized to mint NFTs
        require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");

        // mak sure that the redeemer has enough balance of creator token to pay with
        require(msg.sender.balance >= msg.value, "Insuefficient balance to redeem");

        // make sure that the redeemer is paying enough to cover the buyer's cost
        require(msg.value >= voucher.minPrice, "Redeem price too low");

        // transfer redeem payment to the contract
        sendValue(payable(msg.sender), msg.value);

        // first assign the token to the signer, to establish provenance on-chain
        _mint(signer, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.uri);

        // transfer the token to the redeemer
        _transfer(signer, msg.sender, voucher.tokenId);

        return voucher.tokenId;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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

    function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        if (gated) {
            return _getTokenURI(tokenId);
        } else {
            return super.tokenURI(tokenId);
        }
    }

    function _getTokenURI(uint256 tokenId) internal view virtual returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) || AccessControlUpgradeable.supportsInterface(interfaceId);
    }
}
