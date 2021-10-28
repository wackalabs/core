// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "../curves/BancorBondingCurve.sol";
import "../lib/ValidGasPrice.sol";

abstract contract ContinuousTokenUpgradeable is Ownable, ERC20Upgradeable, BancorBondingCurve, ValidGasPrice {
    using SafeMath for uint256;

    event Minted(address sender, uint256 amount, uint256 deposit);
    event Burned(address sender, uint256 amount, uint256 refund);

    constructor(uint32 _reserveRatio) BancorBondingCurve(_reserveRatio) {}

    function _msgSender() internal view override(Context, ContextUpgradeable) returns (address sender) {
        sender = ContextUpgradeable._msgSender();
    }

    function _msgData() internal view override(Context, ContextUpgradeable) returns (bytes calldata) {
        return ContextUpgradeable._msgData();
    }

    function _initialize(
        address _creator,
        uint256 _initialSupply,
        string memory _name,
        string memory _symbol
    ) internal initializer {
        // initialize inherited contracts
        __ERC20_init(_name, _symbol);
        _mint(_creator, _initialSupply);
    }

    function continuousSupply() public view override returns (uint256) {
        return totalSupply(); // Continuous Token total supply
    }

    function _continuousMint(uint256 _deposit) internal validGasPrice returns (uint256) {
        require(_deposit > 0, "Deposit must be non-zero.");

        uint256 rewardAmount = getContinuousMintReward(_deposit);
        _mint(msg.sender, rewardAmount);
        emit Minted(msg.sender, rewardAmount, _deposit);
        return rewardAmount;
    }

    function _continuousBurn(uint256 _amount) internal validGasPrice returns (uint256) {
        require(_amount > 0, "Amount must be non-zero.");
        require(balanceOf(msg.sender) >= _amount, "Insufficient tokens to burn.");

        uint256 refundAmount = getContinuousBurnRefund(_amount);
        _burn(msg.sender, _amount);
        emit Burned(msg.sender, _amount, refundAmount);
        return refundAmount;
    }

    function sponsoredBurn(uint256 _amount) public {
        _burn(msg.sender, _amount);
        emit Burned(msg.sender, _amount, 0);
    }
}
