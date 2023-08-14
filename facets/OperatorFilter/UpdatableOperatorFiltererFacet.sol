// SPDX-License-Identifier: MIT
// Forked from operator-filter-registry v1.4.2 (operator-filter-registry/src/UpdatableOperatorFilterer.sol)

pragma solidity ^0.8.20;

import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import {UpdatableOperatorFiltererInternal} from "./UpdatableOperatorFiltererInternal.sol";
import {IOperatorFilterRegistry} from "../../interfaces/IOperatorFilterRegistry.sol";

/**
 *  ╔╗  ╔╗╔╗      ╔╗ ╔╗     ╔╗
 *  ║╚╗╔╝╠╝╚╗     ║║ ║║     ║║
 *  ╚╗║║╔╬╗╔╬═╦╦══╣║ ║║  ╔══╣╚═╦══╗
 *   ║╚╝╠╣║║║╔╬╣╔╗║║ ║║ ╔╣╔╗║╔╗║══╣
 *   ╚╗╔╣║║╚╣║║║╚╝║╚╗║╚═╝║╔╗║╚╝╠══║
 *    ╚╝╚╝╚═╩╝╚╩══╩═╝╚═══╩╝╚╩══╩══╝
 */

/**
 * @title  UpdatableOperatorFilterer
 * @notice Implementation contract of the abstract UpdatableOperatorFiltererInternal. This contract allows the Owner
 *         to update the OperatorFilterRegistry address via updateOperatorFilterRegistryAddress, including to the zero
 *         address, which will bypass registry checks. Note that OpenSea will still disable creator earnings enforcement
 *         if filtered operators begin fulfilling orders on-chain, eg, if the registry is revoked or bypassed.
 *
 *         Updated to support EIP-2535 Diamond standard
 */
contract UpdatableOperatorFiltererFacet is UpdatableOperatorFiltererInternal, OwnableInternal {
    /**
     * @notice Update the address that the contract will make OperatorFilter checks against. When set to the zero
     *         address, checks will be bypassed. OnlyOwner.
     */
    function updateOperatorFilterRegistryAddress(address newRegistry) public virtual {
        _updateOperatorFilterRegistryAddress(newRegistry);
    }

    /**
     * @notice Returns the address of the current operatorFilterRegistry
     */
    function operatorFilterRegistry() public view returns (address) {
        return _operatorFilterRegistry();
    }

    /**
     * @notice Implement the abstract _owner method for parent contract use.
     */
    function _owner() internal view override(UpdatableOperatorFiltererInternal, OwnableInternal) returns (address) {
        return OwnableInternal._owner();
    }
}
