// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract EneptiAccount is AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant ACCOUNT_REGISTRY_ROLE = keccak256("ACCOUNT_REGISTRY_ROLE");

    EnumerableSet.AddressSet private accounts;

    function mint(address to) public onlyAccountRegistry {
        accounts.add(to);
    }

    function hasAccount(address who) public view returns (bool) {
        return EnumerableSet.contains(accounts, who);
    }

    modifier onlyAccountRegistry() {
        require(hasRole(ACCOUNT_REGISTRY_ROLE, msg.sender), "EneptiAccount: caller is not Account Registry");
        _;
    }
}
