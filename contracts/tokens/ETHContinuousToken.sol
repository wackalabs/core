// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../interfaces/IWETH.sol";
import "./ContinuousToken.sol";

contract ETHContinuousToken is ContinuousToken {
    using SafeMath for uint256;

    /// @notice weth address
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 internal reserve;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        uint32 _reserveRatio
    ) payable ContinuousToken(_name, _symbol, _initialSupply, _reserveRatio) {
        reserve = msg.value;
    }

    receive() external payable {
        mint();
    }

    fallback() external payable {
        mint();
    }

    function mint() public payable {
        uint256 purchaseAmount = msg.value;
        _continuousMint(purchaseAmount);
        reserve = reserve.add(purchaseAmount);
    }

    function burn(uint256 _amount) public {
        uint256 refundAmount = _continuousBurn(_amount);
        reserve = reserve.sub(refundAmount);
        _sendETHOrWETH(msg.sender, refundAmount);
    }

    function reserveBalance() public view override returns (uint256) {
        return reserve;
    }

    /// --------------------------------
    /// -------- CORE FUNCTIONS --------
    /// --------------------------------

    // Will attempt to transfer ETH, but will transfer WETH instead if it fails.
    function _sendETHOrWETH(address to, uint256 value) internal {
        // Try to transfer ETH to the given recipient.
        if (!_attemptETHTransfer(to, value)) {
            // If the transfer fails, wrap and send as WETH, so that
            // the auction is not impeded and the recipient still
            // can claim ETH via the WETH contract (similar to escrow).
            IWETH(weth).deposit{ value: value }();
            IWETH(weth).transfer(to, value);
            // At this point, the recipient can unwrap WETH.
        }
    }

    // Sending ETH is not guaranteed complete, and the method used here will return false if
    // it fails. For example, a contract can block ETH transfer, or might use
    // an excessive amount of gas, thereby griefing a new bidder.
    // We should limit the gas used in transfers, and handle failure cases.
    function _attemptETHTransfer(address to, uint256 value) internal returns (bool) {
        // Here increase the gas limit a reasonable amount above the default, and try
        // to send ETH to the recipient.
        // NOTE: This might allow the recipient to attempt a limited reentrancy attack.
        (bool success, ) = to.call{ value: value, gas: 30000 }("");
        return success;
    }
}
