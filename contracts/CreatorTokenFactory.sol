// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "./InitializedProxy.sol";
import "./Settings.sol";
import "./CreatorTokenVault.sol";

contract ERC721VaultFactory is Ownable, Pausable {
    /// @notice the number of ERC721 vaults
    uint256 public vaultCount;

    /// @notice the mapping of vault number to vault contract
    mapping(uint256 => address) public vaults;

    /// @notice a settings contract controlled by governance
    address public immutable settings;
    /// @notice the CreatorTokenVault logic contract
    address public immutable logic;

    event TokenVaultCreated(string tokenName, string tokenSymbol, uint256 price, address vault, uint256 vaultId);

    constructor(address _settings) {
        settings = _settings;
        logic = address(new CreatorTokenVault(_settings));
    }

    /// @notice the function to mint a new vault
    /// @param _name the desired name of the vault
    /// @param _symbol the desired sumbol of the vault
    /// @param _listPrice the initial price of the creator token on the bonding curve
    /// @return the ID of the vault
    function mint(
        string memory _name,
        string memory _symbol,
        uint256 _supply,
        uint256 _listPrice,
        uint256 _fee
    ) external whenNotPaused returns (uint256) {
        bytes memory _initializationCalldata = abi.encodeWithSignature(
            "initialize(address,uint256,uint256,uint256,string,string)",
            msg.sender,
            _supply,
            _listPrice,
            _fee,
            _name,
            _symbol
        );

        address vault = address(new InitializedProxy(logic, _initializationCalldata));

        emit TokenVaultCreated(_name, _symbol, _listPrice, vault, vaultCount);

        vaults[vaultCount] = vault;
        vaultCount++;

        return vaultCount - 1;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
