// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IRenderMetadata} from "../interfaces/IRenderMetadata.sol";
import {SeedStorage} from "../libraries/storage/SeedStorage.sol";
import {DNALib} from "../libraries/DNALib.sol";
import {RelicMetadata} from "../libraries/RelicMetadata.sol";
import {HTMLUtil} from "../libraries/HTMLUtil.sol";
import {Base64} from "../libraries/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {MintStorage} from "../libraries/storage/MintStorage.sol";

/**
 *  ╔╗  ╔╗╔╗      ╔╗ ╔╗     ╔╗
 *  ║╚╗╔╝╠╝╚╗     ║║ ║║     ║║
 *  ╚╗║║╔╬╗╔╬═╦╦══╣║ ║║  ╔══╣╚═╦══╗
 *   ║╚╝╠╣║║║╔╬╣╔╗║║ ║║ ╔╣╔╗║╔╗║══╣
 *   ╚╗╔╣║║╚╣║║║╚╝║╚╗║╚═╝║╔╗║╚╝╠══║
 *    ╚╝╚╝╚═╩╝╚╩══╩═╝╚═══╩╝╚╩══╩══╝
 */

/**
 * @title  RenderMetadataFacet
 * @author slvrfn
 * @notice The role of this contract is to handle how each Relic is rendered.
 * @dev    This contract is separated to allow for later rendering updates if needed
 */
contract RenderMetadataFacet is IRenderMetadata {
    using SeedStorage for SeedStorage.Layout;
    using MintStorage for MintStorage.Layout;

    /**
     * @dev Raised if a user tries to use an Invalid Token id.
     */
    error InvalidToken();

    // a condensed mapping in the form
    //  gene[5][
    //      rarity[4]: [
    //          common:[3],
    //          uncommon:[3],
    //          rare:[3],
    //          mythic:[3],
    //      ]
    //  ]
    bytes internal constant DENSE_MAPPING =
        hex"000000010203040506070809000000010200030405060700000000040200030500010700000102030405060708090a0b000000010200030405060700";
    // a condensed mapping in the form
    //      rarity[1]: [
    //          common:[3],
    //          uncommon:[3],
    //          rare:[3],
    //          mythic:[3],
    //      ]
    bytes internal constant BEHIND_MAPPING = hex"000000000000010001010101";
    // a condensed mapping in the form
    //      genes[5]: [
    //          rarity:[4]
    //      ]
    bytes internal constant LEN_MAPPING = hex"0103030301020302010202020303030301020302";
    string internal constant HTML_HEADER =
        "<html><head><style>.l{position:relative}.l img{height:auto;width:100%}.o{position:absolute;top:0;left:0}.i{opacity:.15}</style></head><body>";
    string internal constant HTML_FOOTER = "</body></html>";

    function assembleAttribute(string memory key, string memory value, bool first) internal pure returns (string memory) {
        string[5] memory attr = [",", "{", HTMLUtil.getObjMapping("trait_type", key, false), HTMLUtil.getObjMapping("value", value, true), "}"];

        // some attributes can be missing, handle this by switching "," placement
        if (first) {
            attr[0] = "";
        }

        return string.concat(attr[0], attr[1], attr[2], attr[3], attr[4]);
    }

    function assembleHTMLAttrs(uint256 tokenDNA, string memory baseUrl) internal pure returns (string memory, string memory) {
        // extract the first 20 genes (5 groups of DOM REC REC REC) of length 4 bits from the tokenDNA
        uint8[] memory genes = DNALib.decodeDna(tokenDNA, 20, 5);

        // extra layer to allow asset re-ordering
        // bg, (beast?), steps, <geneOrder>
        // if beast is behind, layer1=beast layer3=""
        // if beast is normal, layer1="" layer3=beast
        string[6] memory layers = [
            "", // optional beast
            "",
            "",
            "",
            "",
            "" // main traits (optional exclude beast)
        ];
        string[5] memory attrs = ["", "", "", "", ""];

        // track which trait is getting added to the output first
        // allows multiple traits to be missing
        bool first = true;

        for (uint8 geneInd = 0; geneInd < 5; ) {
            // offset into the dna's genes, genes are in groups of 4 (DOM REC REC REC)
            uint8 domInd = geneInd * 4;
            uint8 geneRarity = RelicMetadata.getGeneRarity(genes[domInd]);
            // max range 3 (0..2)
            uint16 chosen = ((genes[domInd + 1] + genes[domInd + 2]) * uint16(genes[domInd + 3])) % uint8(LEN_MAPPING[domInd + geneRarity]);
            // offset into the struct
            uint16 rarityOffset = geneRarity * 3;
            // max range 12 (0..11)
            uint8 chosenOption = uint8(DENSE_MAPPING[(12 * geneInd) + rarityOffset + chosen]);
            // check if this asset should be skipped
            if (!(chosenOption == 0 && geneInd != 3)) {
                // offset by 1 to allow for optional asset places before others
                uint8 placement = (geneInd == 0 && uint8(BEHIND_MAPPING[rarityOffset + chosen]) == 1) ? 0 : geneInd + 1;
                layers[placement] = HTMLUtil.getHTMLImage(
                    string.concat(RelicMetadata.getGeneName(geneInd, false), "_", RelicMetadata.getAssetInfo(geneInd, chosenOption, false), ".png"),
                    baseUrl,
                    "o"
                );
                attrs[geneInd] = assembleAttribute(
                    RelicMetadata.getGeneName(geneInd, true),
                    RelicMetadata.getAssetInfo(geneInd, chosenOption, true),
                    first
                );
                first = false;
            }
            // save some gas
            unchecked {
                ++geneInd;
            }
        }

        string memory inner = HTMLUtil.getDivWrap(
            string.concat(
                HTMLUtil.getHTMLImage("bg.png", baseUrl, "o"),
                layers[0],
                HTMLUtil.getHTMLImage("steps.png", baseUrl, "o"),
                layers[1],
                layers[2],
                layers[3],
                layers[4],
                layers[5],
                HTMLUtil.getHTMLImage("fog.png", baseUrl, "o i")
            ),
            "l"
        );

        return (
            string.concat("data:text/html;base64,", Base64.encode(abi.encodePacked(HTML_HEADER, inner, HTML_FOOTER), false)),
            string.concat("[", attrs[0], attrs[1], attrs[2], attrs[3], attrs[4], "]")
        );
    }

    /**
     * @notice Returns DNA associated with a Relic
     * @param  tokenId - the token id associated with some DNA.
     */
    function tokenDna(uint256 tokenId) public view returns (uint256) {
        MintStorage.Layout storage m = MintStorage.layout();
        // if checking un-minted token, raise error
        if (tokenId >= m._tokenIdCounter()) {
            revert InvalidToken();
        }

        uint256 globalSeed = SeedStorage.layout()._seed();
        // derive the tokens "dna" from its tokenId hashed with the global seed
        return uint256(keccak256(abi.encodePacked(globalSeed, tokenId)));
    }

    /**
     * @notice Renders metadata for a Relic.
     * @dev    Bytes used here to allow for potential future iterations to pass different data required for rendering.
     * @param  tokenId - the tokenId associated with this seed update.
     * @param  data - Encoded data for use in rendering Relic metadata.
     */
    function renderMetadata(uint256 tokenId, bytes calldata data) public view returns (string memory) {
        // derive the tokens "dna" from its tokenId hashed with the global seed
        uint256 tokenDNA = tokenDna(tokenId);

        (string memory baseUrl, string memory baseRelicUrl) = abi.decode(data, (string, string));

        string memory tokenStr = Strings.toString(tokenId);

        string memory relicName = string.concat("Relic ", tokenStr);
        string memory relicUrl = string.concat(baseRelicUrl, tokenStr);

        (string memory encodedHtml, string memory attributes) = assembleHTMLAttrs(tokenDNA, baseUrl);

        //data:application/json;base64,
        //data:text/html;base64,

        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        "{",
                        HTMLUtil.getObjMapping("description", "A mysterious object that offers unfathomable power in the VLVerse", false),
                        HTMLUtil.getObjMapping("external_url", relicUrl, false),
                        HTMLUtil.getObjMapping("animation_url", encodedHtml, false),
                        HTMLUtil.getObjMapping("name", relicName, false),
                        HTMLUtil.getObjMapping("attributes", attributes, true, true),
                        "}"
                    ),
                    false
                )
            );
    }
}
