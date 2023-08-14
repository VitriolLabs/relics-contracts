// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC165BaseInternal} from "@solidstate/contracts/introspection/ERC165/base/ERC165BaseInternal.sol";
import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";
import {IAccessControl} from "@solidstate/contracts/access/access_control/IAccessControl.sol";
import {ERC721MetadataStorage} from "@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol";
import {ERC721MetadataInternal} from "@solidstate/contracts/token/ERC721/metadata/ERC721MetadataInternal.sol";
import {IERC721} from "@solidstate/contracts/interfaces/IERC721.sol";
import {IERC721Enumerable} from "@solidstate/contracts/token/ERC721/enumerable/IERC721Enumerable.sol";
import {IERC721Metadata} from "@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IRenderMetadata} from "../interfaces/IRenderMetadata.sol";
import {BaseStorage} from "../base/BaseStorage.sol";
import {FeatureFlag} from "../base/FeatureFlag.sol";
import {AppStorageInternal} from "../facets/AppStorage/AppStorageInternal.sol";
import {SeedStorage} from "../libraries/storage/SeedStorage.sol";
import {LibAppStorage} from "../libraries/storage/LibAppStorage.sol";
import {MintStorage} from "../libraries/storage/MintStorage.sol";
import {TokenStorage} from "../libraries/storage/TokenStorage.sol";
import {LibEIP712} from "../libraries/LibEIP712.sol";
import {MintInternal} from "../facets/Mint/MintInternal.sol";
import {SeedInternal} from "../facets/Seed/SeedInternal.sol";
import {UpdatableOperatorFiltererInternal} from "../facets/OperatorFilter/UpdatableOperatorFiltererInternal.sol";

/**
 *  ╔╗  ╔╗╔╗      ╔╗ ╔╗     ╔╗
 *  ║╚╗╔╝╠╝╚╗     ║║ ║║     ║║
 *  ╚╗║║╔╬╗╔╬═╦╦══╣║ ║║  ╔══╣╚═╦══╗
 *   ║╚╝╠╣║║║╔╬╣╔╗║║ ║║ ╔╣╔╗║╔╗║══╣
 *   ╚╗╔╣║║╚╣║║║╚╝║╚╗║╚═╝║╔╗║╚╝╠══║
 *    ╚╝╚╝╚═╩╝╚╩══╩═╝╚═══╩╝╚╩══╩══╝
 */

/**
 * @title  DiamondInit
 * @author slvrfn
 * @notice Contract which contains the necessary logic to initialize the Relics Diamond.
 * @dev    This contract is meant to be called on the initial Diamond cut
 */
contract DiamondInit is AppStorageInternal, MintInternal, SeedInternal, ERC165BaseInternal, UpdatableOperatorFiltererInternal {
    using LibEIP712 for LibEIP712.Layout;
    using MintStorage for MintStorage.Layout;
    using TokenStorage for TokenStorage.Layout;
    using ERC721MetadataStorage for ERC721MetadataStorage.Layout;

    struct Args {
        uint32 maxTokens;
        uint16 maxTokensPerAddress;
        uint256[3] mintingFees;
        string baseUri;
        string baseRelicUri;
        uint40 seedExpiration;
        string name;
        string symbol;
        address friendsSigner;
        address fcfsSigner;
        address publicSigner;
        address royaltyRecipient;
        uint16 royaltyPct;
        address diamondAddress;
    }

    /**
     * @dev The init call is intended to only be called once
     */
    function init(Args memory args) external {
        // version on 1 on initial deployment
        string memory version = "1";

        AppStorageInternal._setMaxTokens(args.maxTokens);
        AppStorageInternal._setRoyaltyInfo(args.royaltyRecipient, args.royaltyPct);

        // adding ERC165 data (supported interfaces)
        //ERC165BaseInternal._setSupportsInterface(type(IERC165).interfaceId, true); // set in Diamond constructor
        ERC165BaseInternal._setSupportsInterface(type(IERC721).interfaceId, true);
        ERC165BaseInternal._setSupportsInterface(type(IERC721Enumerable).interfaceId, true);
        ERC165BaseInternal._setSupportsInterface(type(IERC721Metadata).interfaceId, true);
        ERC165BaseInternal._setSupportsInterface(type(IERC2981).interfaceId, true);
        ERC165BaseInternal._setSupportsInterface(type(IRenderMetadata).interfaceId, true);

        ERC721MetadataStorage.layout().name = args.name;
        ERC721MetadataStorage.layout().symbol = args.symbol;
        ERC721MetadataStorage.layout().baseURI = args.baseUri;
        TokenStorage.Layout storage t = TokenStorage.layout();
        t._setBaseRelicUri(args.baseRelicUri);

        // Forked from operator-filter-registry v1.4.2 (operator-filter-registry/src/lib/Constants/Constants.sol)
        UpdatableOperatorFiltererInternal._initOperatorFilter(
            0x000000000000AAeB6D7670E522A718067333cd4E,
            0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6,
            true
        );

        // set the default roles
        AccessControlInternal._grantRole(keccak256("admin"), msg.sender);
        AccessControlInternal._grantRole(keccak256("friendsSigner"), args.friendsSigner);
        AccessControlInternal._grantRole(keccak256("fcfsSigner"), args.friendsSigner);
        AccessControlInternal._grantRole(keccak256("fcfsSigner"), args.fcfsSigner);
        AccessControlInternal._grantRole(keccak256("publicSigner"), args.publicSigner);

        MintStorage.Layout storage m = MintStorage.layout();
        MintInternal._setMintingFee(m, 1, args.mintingFees[0]);
        MintInternal._setMintingFee(m, 2, args.mintingFees[1]);
        MintInternal._setMintingFee(m, 3, args.mintingFees[2]);
        MintInternal._setMaxTokensPerAddress(m, args.maxTokensPerAddress);

        SeedInternal._setExpiration(args.seedExpiration);
        SeedInternal._setRelicSeed(uint256(uint160(address(this))));

        // initially disable seed update
        // no need to set mint bit as the contract starts in a pre-mint phase
        FeatureFlag._setFeatureFlag(0, SEED_BIT);

        /**
         * @dev Initializes the domain separator and parameter caches for LibEIP712.
         *
         * The meaning of `name` and `version` is specified in
         * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
         *
         * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
         * - `version`: the current major version of the signing domain.
         **/
        LibEIP712.Layout storage eipLayout = LibEIP712.layout();
        eipLayout._setup(
            keccak256(bytes(args.name)),
            block.chainid,
            args.diamondAddress,
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
        );
        AppStorageInternal._setVersion(version);
    }

    /**
     * @dev only added to support abstract UpdatableOperatorFiltererInternal function requirement. This is never
     * called, and even if so, this contract has no owner; so returning the 0 address is okay.
     */
    function _owner() internal view override(UpdatableOperatorFiltererInternal) returns (address) {
        return address(0);
    }
}
