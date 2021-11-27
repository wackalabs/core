// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../shared/InitializedProxy.sol";
import "./LazyERC721.sol";

contract LazyERC721Factory is Ownable, Pausable {
    /// @notice the number of ERC721 vaults
    uint256 public vaultCount;

    /// @notice the mapping of vault number to vault contract
    mapping(uint256 => address) public vaults;

    /// @notice the CreatorTokenVault logic contract
    address public logic;

    event LazyERC721Created(
        address creatorToken,
        string tokenName,
        string tokenSymbol,
        string version,
        bool gated,
        address vault,
        uint256 vaultId
    );

    constructor() {
        logic = address(new LazyERC721());
    }

    function mint(
        ERC20 _creatorToken,
        string memory _name,
        string memory _symbol,
        string memory _version,
        bool _gated
    )
        external
        whenNotPaused
        returns (
            address,
            uint256,
            string memory,
            string memory,
            string memory
        )
    {
        bytes memory _initializationCalldata = abi.encodeWithSignature(
            "initialize(address,address,string,string,string,bool)",
            msg.sender,
            _creatorToken,
            _name,
            _symbol,
            _version,
            _gated
        );

        address vault = address(new InitializedProxy(logic, _initializationCalldata));

        emit LazyERC721Created(address(_creatorToken), _name, _symbol, _version, _gated, vault, vaultCount);

        vaults[vaultCount] = vault;
        vaultCount++;

        return (vault, vaultCount - 1, _name, _symbol, _version);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
