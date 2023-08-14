// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721BaseStorage} from "@solidstate/contracts/token/ERC721/base/ERC721BaseStorage.sol";
import {EnumerableSet} from "@solidstate/contracts/data/EnumerableSet.sol";
import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";
import {BaseStorage} from "../../base/BaseStorage.sol";
import {SeedStorage} from "../../libraries/storage/SeedStorage.sol";
import {FeatureFlag} from "../../base/FeatureFlag.sol";

/**
 *  ╔╗  ╔╗╔╗      ╔╗ ╔╗     ╔╗
 *  ║╚╗╔╝╠╝╚╗     ║║ ║║     ║║
 *  ╚╗║║╔╬╗╔╬═╦╦══╣║ ║║  ╔══╣╚═╦══╗
 *   ║╚╝╠╣║║║╔╬╣╔╗║║ ║║ ╔╣╔╗║╔╗║══╣
 *   ╚╗╔╣║║╚╣║║║╚╝║╚╗║╚═╝║╔╗║╚╝╠══║
 *    ╚╝╚╝╚═╩╝╚╩══╩═╝╚═══╩╝╚╩══╩══╝
 */

/**
 * @title  SeedInternal
 * @author slvrfn
 * @notice Abstract contract which contains the necessary logic to manage the seed used for rendering each Relic
 * @dev    This contract is meant to be inherited by contracts so they can use the internal functions
 *         as desired
 */
contract SeedInternal is BaseStorage, AccessControlInternal, FeatureFlag {
    using SeedStorage for SeedStorage.Layout;
    using EnumerableSet for EnumerableSet.UintSet;

    uint40 internal constant EXTEND_TIME = (6 minutes) + (19 seconds);
    /**
     * @dev Broadcast there is a metadata update each time the seed is updated
     */
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    /**
     * @dev Broadcast when the Seed is updated
     */
    event SeedUpdate(uint256 indexed nonce, uint256 seed);
    /**
     * @dev Broadcast when the Seed expiration is updated by an admin
     */
    event ManualSeedExpirationUpdate(uint40 expiration);

    /**
     * @dev Raised if a user tries to update the Seed after the timer has expired.
     */
    error TimerExpired();
    /**
     * @dev Raised if a user tries to update the Seed without being a Relic holder.
     */
    error NotHolder();

    /**
     * @dev   Update the current seed to a provided value and broadcast the update.
     * @param nonce - the nonce associated with this seed update.
     * @param seed - the recipient of the token being minted.
     */
    function _updateSeed(SeedStorage.Layout storage s, uint216 nonce, uint256 seed) internal {
        s._setSeed(seed);
        // notify the seed has been updated
        emit SeedUpdate(nonce, seed);
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    /**
     * @dev Update the current seed to a new "random" value, and extends the timer if it is about to expire
     */
    function _updateRelicSeed() internal {
        SeedStorage.Layout storage s = SeedStorage.layout();
        uint256 blockTime = block.timestamp; // solhint-disable-line not-rely-on-time

        _requireFeaturesEnabled(0, PAUSED_FLAG_BIT | SEED_BIT);

        uint40 exp = s._expirationTime();

        // check if countdown has expired
        if (blockTime >= exp) {
            revert TimerExpired();
        }

        // fail if caller has less than one relic AND not an admin
        if (ERC721BaseStorage.layout().holderTokens[msg.sender].length() < 1) {
            // ensure only make this call if the caller is not a relic holder
            if (!_hasRole(keccak256("admin"), msg.sender)) {
                revert NotHolder();
            }
        }

        // update nonce used in random calc
        uint216 newNonce = s._incNonce();

        // create a new pseudo-random value which is quite hard to "game", and save it
        _updateSeed(s, newNonce, uint256(keccak256(abi.encodePacked(blockTime, msg.sender, block.prevrandao, s._seed(), newNonce))));

        // if countdown expiring in less than 6min19sec, set it to that
        // this accommodates the initial "reveal" window and allows it to be extended indefinitely (until countdown reaches 0)
        if (blockTime >= (exp - EXTEND_TIME)) {
            s._setExpirationTime(uint40(blockTime + EXTEND_TIME));
        }
    }

    /**
     * @dev Gets the current seed
     */
    function _getRelicSeed() internal view returns (uint256) {
        return SeedStorage.layout()._seed();
    }

    /**
     * @dev Gets the current seed expiration time
     */
    function _getExpiration() internal view returns (uint256) {
        return SeedStorage.layout()._expirationTime();
    }

    /**
     * @dev Return the current nonce.
     */
    function _nonce() internal view returns (uint216) {
        return SeedStorage.layout()._nonce();
    }

    /**
     * @dev   Manually set the Seed, and broadcast this was done for transparency.
     * @param seed - the new seed.
     */
    function _setRelicSeed(uint256 seed) internal onlyRole(keccak256("admin")) {
        SeedStorage.Layout storage s = SeedStorage.layout();
        uint216 newNonce = s._incNonce();
        _updateSeed(s, newNonce, seed);
    }

    /**
     * @dev   Update the seed countdown timer's expiration.
     * @param expiration - the new expiration time.
     */
    function _setExpiration(uint40 expiration) internal onlyRole(keccak256("admin")) {
        SeedStorage.Layout storage s = SeedStorage.layout();
        s._setExpirationTime(expiration);
        emit ManualSeedExpirationUpdate(expiration);
    }
}
