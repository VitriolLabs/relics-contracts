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
 * @title  DNALib
 * @author slvrfn
 * @dev    Set of functions for performing bitwise operations on bits
 */
library DNALib {
    error BitLength();

    /// @dev Slice bits from a uint256 value. https://stackoverflow.com/a/6169956/3344317
    /// @param n - a number to sliced
    /// @param size - length of slice in bits
    /// @param startPos - starting position of the slice, starting from the LSB.
    function sliceBits(uint256 n, uint8 size, uint8 startPos) internal pure returns (uint256 result) {
        // change start position by shifting to the right
        result = uint256(n >> startPos);
        // mask to handle size of slice
        result &= uint256((1 << size) - 1);
    }

    /// @dev Set bits inside a uint256 value. Assumes bits being set are all 0 before the operation.
    /// @param n - a number to sliced
    /// @param x - a number to be inserted
    /// @param size - length of slice in bits
    /// @param startPos - starting position of the slice, starting from the LSB.
    function setBits(uint256 n, uint256 x, uint8 size, uint8 startPos) internal pure returns (uint256 result) {
        // set of 1's size of bits trying to be set
        uint256 onesMask = (1 << size) - 1;
        // make sure to only grab the desired bits
        uint256 settingBits = uint256(onesMask & x);
        // move the new bits into the proper position
        settingBits = uint256(settingBits << startPos);
        // move onesMask into position and use to clear bits to allow "set" below
        n = n & ~(onesMask << startPos);
        // set the bits into the original uint
        result = uint256(n | settingBits);
    }

    function setBit(uint256 n, uint8 pos) internal pure returns (uint256 result) {
        result = n | (1 << pos);
    }

    function clearBit(uint256 n, uint8 pos) internal pure returns (uint256 result) {
        result = n & ~(1 << pos);
    }

    function isBitSet(uint256 n, uint8 pos) internal pure returns (bool result) {
        result = 1 == ((n >> pos) & 1);
    }

    /// @dev Get Gene expression from an encoded DNA sequence
    /// @param input bits, encoded as uint
    function getGene(uint256 input, uint8 slot, uint8 size) internal pure returns (uint8) {
        return uint8(sliceBits(input, uint8(size), slot * size));
    }

    // typically for genes 0-255, can map to the full 256 bits with proper care
    function setGene(uint256 input, uint8 set, uint8 slot) internal pure returns (uint256) {
        return setBits(input, set, uint8(5), slot * 5);
    }

    // directly update dna input from set for each element in position
    function updateGenes(uint256 input, uint8[] memory set, uint8[] memory position) internal pure returns (uint256 output) {
        output = input;
        for (uint8 i = 0; i < position.length; ) {
            output = setGene(output, set[i], position[i]);
            // save some gas
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Parse an encoded DNA sequence and returns the requested number of underlying genes
    /// @param dna an encoded DNA sequence
    /// @param numGenes number of genes to extract from the DNA sequence
    /// @return genes the genes that comprise the genetic code, logically divided in stacks of 4, where only the first gene of each stack may express
    function decodeDna(uint256 dna, uint8 numGenes, uint8 geneSize) internal pure returns (uint8[] memory) {
        return decodeDna(dna, numGenes, geneSize, 0);
    }

    function decodeDna(uint256 dna, uint8 numGenes, uint8 geneSize, uint8 startPos) internal pure returns (uint8[] memory genes) {
        genes = new uint8[](numGenes);
        for (uint8 i = 0; i < numGenes; ) {
            genes[i] = getGene(dna, i + startPos, geneSize);
            // save some gas
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Given an array of genes return a number representing the encoded DNA sequence.
    /// @param genes an array of uint8 that is to be stored in the DNA sequence.
    /// @param numBits how many bits are used to store each gene in the DNA sequence.
    /// @return dna Genes appear reversed in the genome, but this is intended behavior. The 0 array index corresponds to the 0th bit (LSB)
    function encodeGenes(uint8[] memory genes, uint8 numBits) internal pure returns (uint256 dna) {
        if (genes.length * numBits > 255) {
            revert BitLength();
        }
        dna = 0;
        uint256 genesLen = genes.length;
        for (uint8 i = 0; i < genesLen; ) {
            dna = dna << numBits;
            // bitwise OR gene with dna
            dna = dna | genes[(genes.length - 1) - i];
            // save some gas
            unchecked {
                ++i;
            }
        }
    }
}
