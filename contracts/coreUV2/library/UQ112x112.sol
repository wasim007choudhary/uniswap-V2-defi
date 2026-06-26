// SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

library UQ112xUQ112 {
    /// @dev notes/Oracles/03-CumulativePriceAndOracle/P3-SolidityImplimentation/P2 all parts, highky recommended to go trhough them befoer coding this!
    uint224 constant Q112 = 2 ** 112;

    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // notes/Oracles/03-CumulativePriceAndOracle/P3-SolidityImplimentation/P2
    }

    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}
