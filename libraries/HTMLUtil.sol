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
 * @title  HTMLUtil
 * @author slvrfn
 * @notice Library responsible for helping construct a dynamic HTML page of images.
 */
/* solhint-disable quotes */
library HTMLUtil {
    function getHTMLImage(string memory asset, string memory baseURL, string memory class) internal pure returns (string memory) {
        return string.concat("<img class='", class, "' src='", baseURL, asset, "'/>");
    }

    function getDivWrap(string memory data, string memory class) internal pure returns (string memory) {
        return string.concat("<div class='", class, "'>", data, "</div>");
    }

    function getObjMapping(string memory key, string memory value, bool last) internal pure returns (string memory) {
        return getObjMapping(key, value, last, false);
    }

    function getObjMapping(string memory key, string memory value, bool last, bool skipQuotes) internal pure returns (string memory) {
        string[6] memory map = ['"', key, '":"', value, '"', ","];

        if (last) {
            map[5] = "";
        }
        if (skipQuotes) {
            map[2] = '":';
            map[4] = "";
        }

        return string.concat(map[0], map[1], map[2], map[3], map[4], map[5]);
    }
}
/* solhint-enable quotes */
