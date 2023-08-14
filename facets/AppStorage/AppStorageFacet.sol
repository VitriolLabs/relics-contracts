// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";
import {ERC165BaseInternal} from "@solidstate/contracts/introspection/ERC165/base/ERC165BaseInternal.sol";
import {BaseStorage} from "../../base/BaseStorage.sol";
import {AppStorageInternal} from "./AppStorageInternal.sol";
import {Base64} from "../../libraries/Base64.sol";

/**
 *  ╔╗  ╔╗╔╗      ╔╗ ╔╗     ╔╗
 *  ║╚╗╔╝╠╝╚╗     ║║ ║║     ║║
 *  ╚╗║║╔╬╗╔╬═╦╦══╣║ ║║  ╔══╣╚═╦══╗
 *   ║╚╝╠╣║║║╔╬╣╔╗║║ ║║ ╔╣╔╗║╔╗║══╣
 *   ╚╗╔╣║║╚╣║║║╚╝║╚╗║╚═╝║╔╗║╚╝╠══║
 *    ╚╝╚╝╚═╩╝╚╩══╩═╝╚═══╩╝╚╩══╩══╝
 */

/**
 * @title  AppStorageFacet
 * @author slvrfn
 * @notice Implementation contract of the abstract AppStorageInternal. The role of this contract is to manage
 *         high-level parameters of the overall Diamond which are optionally consumed in attached facet contracts.
 */
contract AppStorageFacet is AppStorageInternal, AccessControlInternal, ERC165BaseInternal {
    /**
     * @notice Returns max tokens.
     */
    function maxTokens() public view returns (uint32) {
        return AppStorageInternal._getMaxTokens();
    }

    function contractURI() public pure returns (string memory) {
        //        {
        //          "name": "VL Relics",
        //          "description": "The Relics are mysterious objects that offers unfathomable power in the VLVerse",
        //          "image": "https://arweave.net/tJDdEK195qrEoBHEAEnB6sHI-Ijppoxq7cTt5UlVGrA/relics.gif",
        //          "external_link": "https://relics.vitriol.sh"
        //        }
        return
            string.concat(
                "data:application/json;utf8,",
                Base64.encode(
                    abi.encodePacked(
                        "{'name':'The VL Relics','description':'The Relics are mysterious objects that offers unfathomable power in the VLVerse','image':'https://arweave.net/tJDdEK195qrEoBHEAEnB6sHI-Ijppoxq7cTt5UlVGrA/relics.gif','external_link':'https://relics.vitriol.sh'}"
                    ),
                    false
                )
            );
    }

    /**
     * @notice Returns current EIP-712 compatible version.
     */
    function getHashedVersion() external view returns (bytes32) {
        return AppStorageInternal._getHashedVersion();
    }

    /**
     * @notice Updates the max tokens for this Diamond.
     * @param newCount - the new value to assign to maxTokens.
     */
    function setMaxTokens(uint32 newCount) external onlyRole(keccak256("admin")) {
        AppStorageInternal._setMaxTokens(newCount);
    }

    /**
     * @notice Updates the current EIP-712 compatible version.
     * @param newVersion - the new value to assign to version.
     */
    function setVersion(string memory newVersion) external onlyRole(keccak256("admin")) {
        AppStorageInternal._setVersion(newVersion);
    }

    /**
     * @notice Returns current feature flags set for a particular flagGroup.
     * @param flagGroup - the group of flags to be returned.
     */
    function getFeatureFlagsInGroup(uint256 flagGroup) external view returns (uint256) {
        return AppStorageInternal._getFeatureFlagsInGroup(flagGroup);
    }

    /**
     * @notice Updates the current feature flags for a particular flagGroup.
     * @param flagGroup - the group of flags to be updated.
     * @param value - a number representing a 256-bit bitmask to set at group flagGroup.
     */
    function setFeatureFlagsInGroup(uint256 flagGroup, uint256 value) external onlyRole(keccak256("admin")) {
        AppStorageInternal._setFeatureFlagsInGroup(flagGroup, value);
    }

    /**
     * @notice Returns current ERC-2981 compatible royalty info.
     * @param tokenId - unused - the tokenId to assign royalty info for.
     * @param salePrice - the price to calculate royalty info against.
     */
    // solhint-disable-next-line no-unused-vars
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return AppStorageInternal._royaltyInfo(tokenId, salePrice);
    }

    /**
     * @notice Updates current ERC-2981 compatible royalty info.
     * @param recipient - the new recipient of royalty funds.
     * @param royaltyPct - the percent value used to calculate royalties. Stored as an integer, where 1 = 0.01%.
     */
    function setRoyaltyInfo(address recipient, uint16 royaltyPct) external onlyRole(keccak256("admin")) {
        AppStorageInternal._setRoyaltyInfo(recipient, royaltyPct);
    }

    /**
     * @notice sets status of interface support
     * @param interfaceId id of interface to set status for
     * @param status boolean indicating whether interface will be set as supported
     */
    function setSupportsInterface(bytes4 interfaceId, bool status) external onlyRole(keccak256("admin")) {
        ERC165BaseInternal._setSupportsInterface(interfaceId, status);
    }

    /**
     * @notice Withdraws a specified value from the Diamond to a chosen address.
     * @param to - the recipient of the withdraw.
     * @param amt - the amount of ether to withdraw, measured in wei.
     */
    function withdrawBalance(address payable to, uint256 amt) external onlyRole(keccak256("admin")) {
        AppStorageInternal._withdrawBalance(to, amt);
    }

    /**
     * @notice Returns the chain id of the current blockchain.
     */
    function getChainID() external view returns (uint256) {
        return AppStorageInternal._getChainID();
    }
}
