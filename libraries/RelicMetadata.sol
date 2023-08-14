// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 *  ╔╗  ╔╗╔╗      ╔╗ ╔╗     ╔╗
 *  ║╚╗╔╝╠╝╚╗     ║║ ║║     ║║
 *  ╚╗║║╔╬╗╔╬═╦╦══╣║ ║║  ╔══╣╚═╦══╗
 *   ║╚╝╠╣║║║╔╬╣╔╗║║ ║║ ╔╣╔╗║╔╗║══╣
 *   ╚╗╔╣║║╚╣║║║╚╝║╚╗║╚═╝║╔╗║╚╝╠══║
 *    ╚╝╚╝╚═╩╝╚╩══╩═╝╚═══╩╝╚╩══╩══╝
 */

/**
 * @title  RelicMetadata
 * @author slvrfn
 * @notice Library for storing relic metadata
 */
library RelicMetadata {
    function getGeneRarity(uint32 i) internal pure returns (uint8) {
        if (i < 18) {
            return 0;
        } else if (i < 26) {
            return 1;
        } else if (i < 30) {
            return 2;
        } else {
            return 3;
        }
    }

    function getAssetInfo(uint256 geneInd, uint8 chosenOption, bool upper) internal pure returns (string memory) {
        string memory chosenAsset;

        if (geneInd == 0) {
            // beast
            chosenAsset = getBeastName(chosenOption, upper);
        } else if (geneInd == 3) {
            // object
            chosenAsset = getObjectName(chosenOption, upper);
        } else {
            // color
            chosenAsset = getColorName(chosenOption, upper);
        }
        return chosenAsset;
    }

    function getGeneName(uint8 ind, bool upper) internal pure returns (string memory) {
        string[5] memory genesUpper = ["Beast", "Lightning", "Flame", "Object", "Embers"];
        string[5] memory genes = ["beast", "lightning", "flame", "object", "embers"];

        return upper ? genesUpper[ind] : genes[ind];
    }

    function getBeastName(uint8 ind, bool upper) internal pure returns (string memory) {
        string[10] memory beastsUpper = ["None", "Lion", "Ram", "Gnome", "Snake", "Deerbat", "Phoenix", "Mouth", "Watcher", "Dragon"];
        string[10] memory beasts = ["none", "lion", "ram", "gnome", "snake", "deerbat", "phoenix", "mouth", "watcher", "dragon"];

        return upper ? beastsUpper[ind] : beasts[ind];
    }

    function getObjectName(uint8 ind, bool upper) internal pure returns (string memory) {
        string[12] memory objsUpper = [
            "Coin",
            "Pendant",
            "VL Logo",
            "Book of Alchemy",
            "Spell Book",
            "Beacon",
            "DNA",
            "Key",
            "Hourglass",
            "Portal",
            "Ether",
            "Eye"
        ];
        string[12] memory objs = [
            "coin",
            "pendant",
            "logo",
            "book_of_alchemy",
            "spell_book",
            "beacon",
            "dna",
            "key",
            "hourglass",
            "portal",
            "ether",
            "eye"
        ];

        return upper ? objsUpper[ind] : objs[ind];
    }

    function getColorName(uint8 ind, bool upper) internal pure returns (string memory) {
        string[8] memory colsUpper = ["none", "White", "Orange", "Green", "Red", "Blue", "Purple", "Black"];
        string[8] memory cols = ["none", "white", "orange", "green", "red", "blue", "purple", "black"];

        return upper ? colsUpper[ind] : cols[ind];
    }
}
