// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import { RealmStorage } from "./RealmStorage.sol";

interface IRealmFactory {
    function mediaAddress() external returns (address);

    function logic() external returns (address);

    // ERC20 data.
    function parameters()
        external
        returns (
            address payable operator,
            address payable realmRecipient,
            uint256 realmCap,
            uint256 operatorPercent,
            string memory name,
            string memory symbol
        );
}

/**
 * @title RealmProxy
 * @author enepti
 */
contract RealmProxy is RealmStorage {
    constructor() {
        logic = IRealmFactory(msg.sender).logic();
        // Realm-specific data.
        (operator, realmRecipient, realmCap, operatorPercent, name, symbol) = IRealmFactory(msg.sender).parameters();
        // Initialize mutable storage.
        status = Status.ACTIVE;
    }

    fallback() external payable {
        address _impl = logic;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    receive() external payable {}
}
