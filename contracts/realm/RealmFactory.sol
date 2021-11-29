// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import { RealmProxy } from "./RealmProxy.sol";

/**
 * @title RealmFactory
 * @author enepti
 */
contract RealmFactory {
    //======== Structs ========

    struct Parameters {
        address payable operator;
        address payable realmRecipient;
        uint256 realmCap;
        uint256 operatorPercent;
        string name;
        string symbol;
    }

    //======== Events ========

    event RealmDeployed(address RealmProxy, string name, string symbol, address operator);

    //======== Immutable storage =========

    address public immutable logic;

    //======== Mutable storage =========

    // Gets set within the block, and then deleted.
    Parameters public parameters;

    //======== Constructor =========

    constructor(address logic_) {
        logic = logic_;
    }

    //======== Deploy function =========

    function createRealm(
        string calldata name_,
        string calldata symbol_,
        address payable operator_,
        address payable realmRecipient_,
        uint256 realmCap_,
        uint256 operatorPercent_
    ) external returns (address realmProxy) {
        parameters = Parameters({
            name: name_,
            symbol: symbol_,
            operator: operator_,
            realmRecipient: realmRecipient_,
            realmCap: realmCap_,
            operatorPercent: operatorPercent_
        });

        realmProxy = address(new RealmProxy{ salt: keccak256(abi.encode(name_, symbol_, operator_)) }());

        delete parameters;

        emit RealmDeployed(realmProxy, name_, symbol_, operator_);
    }
}
