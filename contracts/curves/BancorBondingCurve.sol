// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../math/BancorFormula.sol";
import "../lib/ValidGasPrice.sol";
import "../interfaces/IBondingCurve.sol";

abstract contract BancorBondingCurve is IBondingCurve, BancorFormula {
    /*
        reserve ratio, represented in ppm, 1-1000000
        1/3 corresponds to y= multiple * x^2
        1/2 corresponds to y= multiple * x
        2/3 corresponds to y= multiple * x^1/2
    */
    uint32 public reserveRatio;

    constructor(uint32 _reserveRatio) {
        reserveRatio = _reserveRatio;
    }

    function getContinuousMintReward(uint256 _reserveTokenAmount) public view override returns (uint256) {
        return calculatePurchaseReturn(continuousSupply(), reserveBalance(), reserveRatio, _reserveTokenAmount);
    }

    function getContinuousBurnRefund(uint256 _continuousTokenAmount) public view override returns (uint256) {
        return calculateSaleReturn(continuousSupply(), reserveBalance(), reserveRatio, _continuousTokenAmount);
    }

    /**
     * @dev Abstract method that returns continuous token supply
     */
    function continuousSupply() public view virtual returns (uint256);

    /**
     * @dev Abstract method that returns reserve token balance
     */
    function reserveBalance() public view virtual returns (uint256);
}
