// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Settings.sol";
import "./interfaces/IWETH.sol";
import "./tokens/ContinuousTokenUpgradeable.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20CreatorToken is ContinuousTokenUpgradeable {
    using Address for address;

    /// -----------------------------------
    /// -------- VAULT INFORMATION --------
    /// -----------------------------------

    /// @notice the curator address who is the creator of the vault
    address public curator;

    /// @notice reserve token address
    ERC20 public reserveToken;

    constructor(ERC20 _reserveToken, uint32 _reserveRatio) ContinuousTokenUpgradeable(_reserveRatio) {
        reserveToken = _reserveToken;
    }

    function initialize(
        address _curator,
        uint256 _supply,
        string memory _name,
        string memory _symbol
    ) external initializer {
        // initialize inherited contracts
        _initialize(_curator, _supply, _name, _symbol);
        // set storage variables
        curator = _curator;
    }

    function mint(uint256 _amount) public {
        _continuousMint(_amount);
        require(
            reserveToken.transferFrom(msg.sender, address(this), _amount),
            "ERC20CreatorToken mint() ERC20.transferFrom failed."
        );
    }

    function burn(uint256 _amount) public {
        uint256 returnAmount = _continuousBurn(_amount);
        require(reserveToken.transfer(msg.sender, returnAmount), "ERC20CreatorToken burn() ERC20.transfer failed.");
    }

    function reserveBalance() public view override returns (uint256) {
        return reserveToken.balanceOf(address(this));
    }
}
