// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ContinuousToken.sol";

// Need additional attributes for creator / caretaker address and fees
// creatorAddress
// mintCreatorFee
// burnCreatorFee
// caretakerAddress
// caretakerFee
// mintCaretakerFee
// burnCaretakerFee
// TODO: Define ERC20ContinuousTokenWithFees
contract ERC20ContinuousToken is ContinuousToken {
    ERC20 public reserveToken;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        uint32 _reserveRatio,
        ERC20 _reserveToken
    ) ContinuousToken(_name, _symbol, _initialSupply, _reserveRatio) {
        reserveToken = _reserveToken;
    }

    function mint(uint256 _amount) public {
        _continuousMint(_amount);
        require(reserveToken.transferFrom(msg.sender, address(this), _amount), "mint() ERC20.transferFrom failed.");
    }

    function burn(uint256 _amount) public {
        uint256 returnAmount = _continuousBurn(_amount);
        require(reserveToken.transfer(msg.sender, returnAmount), "burn() ERC20.transfer failed.");
    }

    function reserveBalance() public view override returns (uint256) {
        return reserveToken.balanceOf(address(this));
    }
}
