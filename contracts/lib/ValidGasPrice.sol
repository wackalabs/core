// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ValidGasPrice is Ownable {
    uint256 public maxGasPrice = 1 * 10**18;

    modifier validGasPrice() {
        require(tx.gasprice <= maxGasPrice, "Gas price too high.");
        _;
    }

    function setMaxGasPrice(uint256 newPrice) public onlyOwner {
        maxGasPrice = newPrice;
    }
}
