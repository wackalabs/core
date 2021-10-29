// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EneptiToken is ERC721PresetMinterPauserAutoId, Ownable {
    bytes32 public constant ACCOUNT_MANAGER_ROLE = keccak256("ACCOUNT_MANAGER_ROLE");

    constructor() ERC721PresetMinterPauserAutoId("Enepti Token", "ENEPTI", "") {
        mint(msg.sender);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {}

    modifier onlyAccountManager() {
        require(hasRole(ACCOUNT_MANAGER_ROLE, msg.sender), "EneptiToken: caller is not Account Manager");
        _;
    }
}
