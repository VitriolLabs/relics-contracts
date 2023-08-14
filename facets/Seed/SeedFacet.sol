// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SeedInternal} from "./SeedInternal.sol";
import {SeedStorage} from "../../libraries/storage/SeedStorage.sol";

/**
 *  ╔╗  ╔╗╔╗      ╔╗ ╔╗     ╔╗
 *  ║╚╗╔╝╠╝╚╗     ║║ ║║     ║║
 *  ╚╗║║╔╬╗╔╬═╦╦══╣║ ║║  ╔══╣╚═╦══╗
 *   ║╚╝╠╣║║║╔╬╣╔╗║║ ║║ ╔╣╔╗║╔╗║══╣
 *   ╚╗╔╣║║╚╣║║║╚╝║╚╗║╚═╝║╔╗║╚╝╠══║
 *    ╚╝╚╝╚═╩╝╚╩══╩═╝╚═══╩╝╚╩══╩══╝
 */

/**
 * @title  SeedFacet
 * @author slvrfn
 * @notice Implementation contract of the abstract SeedInternal. Which contains the necessary logic to manage the seed
 *         used for rendering each Relic
 */
contract SeedFacet is SeedInternal {
    using SeedStorage for SeedStorage.Layout;

    /**
     * @notice Update the current seed to a new "random" value, and extends the timer if it is about to expire
     */
    function updateRelicSeed() external {
        _updateRelicSeed();
    }

    /**
     * @notice Gets the current seed
     */
    function getRelicSeed() external view returns (uint256) {
        return _getRelicSeed();
    }

    /**
     * @notice Gets the current seed expiration time
     */
    function getExpiration() external view returns (uint256) {
        return _getExpiration();
    }

    /**
     * @notice   Manually set the Seed, and broadcast this was done for transparency.
     * @param seed - the new seed.
     */
    function setRelicSeed(uint256 seed) external onlyRole(keccak256("admin")) {
        _setRelicSeed(seed);
    }

    /**
     * @notice   Update the seed countdown timer's expiration.
     * @param expiration - the new expiration time.
     */
    function setExpiration(uint40 expiration) external onlyRole(keccak256("admin")) {
        _setExpiration(expiration);
    }

    /**
     * @dev Return the current nonce.
     */
    function getNonce() external view returns (uint216) {
        return _nonce();
    }
}
