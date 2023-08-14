// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {BaseStorage} from "../../base/BaseStorage.sol";
import {FeatureFlag} from "../../base/FeatureFlag.sol";
import {LibEIP712} from "../../libraries/LibEIP712.sol";

/**
 *  ╔╗  ╔╗╔╗      ╔╗ ╔╗     ╔╗
 *  ║╚╗╔╝╠╝╚╗     ║║ ║║     ║║
 *  ╚╗║║╔╬╗╔╬═╦╦══╣║ ║║  ╔══╣╚═╦══╗
 *   ║╚╝╠╣║║║╔╬╣╔╗║║ ║║ ╔╣╔╗║╔╗║══╣
 *   ╚╗╔╣║║╚╣║║║╚╝║╚╗║╚═╝║╔╗║╚╝╠══║
 *    ╚╝╚╝╚═╩╝╚╩══╩═╝╚═══╩╝╚╩══╩══╝
 */

/**
 * @title  AppStorageInternal
 * @author slvrfn
 * @notice Abstract contract which contains the necessary logic to manage high-level parameters of the overall
 *         Diamond which are optionally consumed in attached facet contracts.
 * @dev    This contract is meant to be inherited by contracts so they can use the internal functions
 *         as desired
 */
abstract contract AppStorageInternal is BaseStorage, FeatureFlag {
    using LibEIP712 for LibEIP712.Layout;

    event UpdateMaxTokens(uint32 count);
    event UpdateVersion(string version, bytes32 versionHash);
    event UpdateRoyalty(address recipient, uint16 royaltyPct);

    error WithdrawAmount();
    error Withdraw();

    /**
     * @dev Returns max tokens.
     */
    function _getMaxTokens() internal view returns (uint32) {
        return s.maxTokens;
    }

    /**
     * @dev Returns current EIP-712 compatible version.
     */
    function _getHashedVersion() internal view returns (bytes32) {
        return LibEIP712.layout()._hashedVersion();
    }

    /**
     * @dev   Updates the max tokens for this Diamond.
     * @param newCount - the new value to assign to maxTokens.
     */
    function _setMaxTokens(uint32 newCount) internal {
        s.maxTokens = newCount;
        emit UpdateMaxTokens(newCount);
    }

    /**
     * @dev   Updates the current EIP-712 compatible version.
     * @param newVersion - the new value to assign to version.
     */
    function _setVersion(string memory newVersion) internal {
        bytes32 hashedVersion = LibEIP712.layout()._updateVersion(newVersion);
        emit UpdateVersion(newVersion, hashedVersion);
    }

    /**
     * @dev   Returns current feature flags set for a particular flagGroup.
     * @param flagGroup - the group of flags to be returned.
     */
    function _getFeatureFlagsInGroup(uint256 flagGroup) internal view returns (uint256) {
        return super._getFlagGroupBits(flagGroup);
    }

    /**
     * @dev   Updates the current feature flags for a particular flagGroup.
     * @param flagGroup - the group of flags to be updated.
     * @param value - a number representing a 256-bit bitmask to set at group flagGroup.
     */
    function _setFeatureFlagsInGroup(uint256 flagGroup, uint256 value) internal {
        super._setFeatureFlag(flagGroup, value);
    }

    /**
     * @dev   Returns current ERC-2981 compatible royalty info.
     * @param tokenId - unused - the tokenId to assign royalty info for.
     * @param salePrice - the price to calculate royalty info against.
     */
    // solhint-disable-next-line no-unused-vars
    function _royaltyInfo(uint256 tokenId, uint256 salePrice) internal view returns (address receiver, uint256 royaltyAmount) {
        receiver = s.royaltyRecipient;
        royaltyAmount = (salePrice * s.royaltyPct) / 10000;
    }

    /**
     * @dev   Updates current ERC-2981 compatible royalty info.
     * @param recipient - the new recipient of royalty funds.
     * @param royaltyPct - the percent value used to calculate royalties. Stored as an integer, where 1 = 0.01%.
     */
    function _setRoyaltyInfo(address recipient, uint16 royaltyPct) internal {
        s.royaltyRecipient = recipient;
        s.royaltyPct = royaltyPct;
        emit UpdateRoyalty(recipient, royaltyPct);
    }

    /**
     * @dev   Withdraws a specified value from the Diamond to a chosen address.
     * @param to - the recipient of the withdraw.
     * @param amt - the amount of ether to withdraw, measured in wei.
     */
    function _withdrawBalance(address payable to, uint256 amt) internal {
        if (amt > address(this).balance) {
            revert WithdrawAmount();
        }
        (bool sent, ) = to.call{value: amt}("");
        if (!sent) {
            revert Withdraw();
        }
    }

    /**
     * @notice Returns the chain id of the current blockchain.
     * @dev    This is used to workaround an issue with ganache returning different values from the on-chain chainid()
     *         function and the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
     */
    function _getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}
