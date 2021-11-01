// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "./shared/InitializedProxy.sol";
import "./Settings.sol";
import "./ERC20CreatorToken.sol";

contract ERC20CreatorTokenFactory is Ownable, Pausable {
    /// @notice the number of ERC721 vaults
    uint256 public vaultCount;

    struct Vault {
        uint256 id;
        address vault;
        bool exists;
    }

    /// @notice the mapping of vault number to vault contract
    mapping(uint256 => Vault) public vaults;

    /// @notice the ERC20CreatorToken logic contract
    address public immutable logic;

    event CreatorTokenCreated(string tokenName, string tokenSymbol, address vault, uint256 vaultId);

    constructor(ERC20 _reserveToken, uint32 _reserveRatio) {
        logic = address(new ERC20CreatorToken(_reserveToken, _reserveRatio));
    }

    /// @notice the function to mint a new vault
    /// @param _supply the total supply of creator tokens
    /// @param _name the desired name of the vault
    /// @param _symbol the desired sumbol of the vault
    /// @return the ID of the vault
    function mint(
        uint256 _supply,
        string memory _name,
        string memory _symbol
    ) external whenNotPaused returns (uint256) {
        bytes memory _initializationCalldata = abi.encodeWithSignature(
            "initialize(address,uint256,string,string)",
            msg.sender,
            _supply,
            _name,
            _symbol
        );

        address vault = address(new InitializedProxy(logic, _initializationCalldata));

        emit CreatorTokenCreated(_name, _symbol, vault, vaultCount);

        vaults[vaultCount] = Vault(vaultCount, vault, true);
        vaultCount++;

        return vaultCount - 1;
    }

    function getVault(uint256 vaultId) public view returns (address) {
        return vaults[vaultId].vault;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
