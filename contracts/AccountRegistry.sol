// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./EneptiAccount.sol";
import "./EneptiToken.sol";
import "./SocialToken.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract AccountRegistry is ERC721Holder, AccessControl, Ownable {
    bytes32 public constant ACCOUNT_MANAGER_ROLE = keccak256("ACCOUNT_MANAGER_ROLE");

    struct Account {
        bool active;
        bool exists;
    }

    mapping(address => Account) public accounts;

    EneptiToken public tokenContract;
    EneptiAccount public accountContract;

    constructor(address accountAddress, address tokenAddress) {
        accountContract = EneptiAccount(accountAddress);
        tokenContract = EneptiToken(tokenAddress);
    }

    function create(uint256 nftId, uint256[] memory _dna) external hasEneptiToken isApproved onlyAccountManager {
        tokenContract.safeTransferFrom(_msgSender(), address(this), nftId);
        accountContract.mint(_msgSender());

        address _deployment = Create2.computeAddress(
            keccak256(abi.encode(nftId)),
            keccak256(type(SocialToken).creationCode)
        );
        Create2.deploy(0, keccak256(abi.encode(nftId)), type(SocialToken).creationCode);

        accounts[_msgSender()] = Account(true, true);
    }

    function activate(uint256 nftId) external hasAccount isApproved isNotActive onlyAccountManager {
        tokenContract.safeTransferFrom(_msgSender(), address(this), nftId);
        accounts[_msgSender()].active = true;
    }

    function deactivate(uint256 nftId) external hasActivatedAccount onlyAccountManager {
        tokenContract.safeTransferFrom(address(this), _msgSender(), nftId);
        accounts[_msgSender()].active = false;
    }

    function login() external view hasActivatedAccount returns (bool) {
        return accounts[_msgSender()].active;
    }

    modifier hasEneptiToken() {
        require(tokenContract.balanceOf(_msgSender()) > 0, "AccountRegistry: caller doesn't have any ENEPTI NFT token");
        _;
    }

    modifier hasAccount() {
        require(accounts[_msgSender()].exists, "AccountRegistry: caller doesn't have an account");
        _;
    }

    modifier hasActivatedAccount() {
        require(accounts[_msgSender()].active, "AccountRegistry: caller doesn't have an active account");
        _;
    }

    modifier isApproved() {
        require(
            tokenContract.isApprovedForAll(_msgSender(), address(this)),
            "AccountRegistry: missing approval for the NFT transfer"
        );
        _;
    }

    modifier isNotActive() {
        require(!accounts[_msgSender()].active, "AccountRegistry: the account is already active");
        _;
    }

    modifier onlyAccountManager() {
        require(hasRole(ACCOUNT_MANAGER_ROLE, msg.sender), "AccountRegistry: caller is not Account Manager");
        _;
    }
}
