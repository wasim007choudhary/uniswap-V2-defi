// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Math {
    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /**
     * @notice Returns the smaller of two unsigned integers.
     * @dev
     * - Compares `x` and `y` using the ternary operator (`? :`).
     * - If `x` is less than `y`, `x` is returned.
     * - Otherwise, `y` is returned.
     * - If both values are equal, either value may be returned since they are identical.
     * - This is a lightweight helper function used to simplify comparisons throughout the codebase.
     * @param x The first unsigned integer to compare.
     * @param y The second unsigned integer to compare.
     * @return z The smaller of `x` and `y`.
     *
     *  ----------------------------------------------------------------------------------------------------------------
     *  @custom:see For a complete, in-depth dissection: vsist notes/Core/Library/Math.sqrt in the project repository.
     *  ----------------------------------------------------------------------------------------------------------------
     */

    function minOfTwo(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /**
     * @notice Computes the integer square root of an unsigned integer using the Babylonian method.
     * @dev
     * - Returns the largest integer `z` such that `z * z <= y`.
     * - Uses the Babylonian (Newton-Raphson) iterative approximation algorithm.
     * - For values greater than 3, the algorithm:
     *   1. Starts with an initial guess of `y`.
     *   2. Generates a better guess using `(y / x + x) / 2`.
     *   3. Repeats until the approximation no longer improves.
     * - Special cases:
     *   - `0` returns `0`.
     *   - `1`, `2`, and `3` return `1`.
     * - Since the function returns a `uint256`, any fractional part of the true square root
     *   is discarded (rounded down toward zero).
     * @param y The unsigned integer whose integer square root is to be computed.
     * @return z The integer square root of `y`, rounded down to the nearest whole number.
     *
     *  ----------------------------------------------------------------------------------------------------------------
     *  @custom:see For a complete, in-depth dissection: vsist notes/Core/Library/Math.sqrt in the project repository.
     *  ----------------------------------------------------------------------------------------------------------------
     */
    function squareRoot(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

