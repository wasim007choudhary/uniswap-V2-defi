// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Math {
    function minOfTwo(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }
}
