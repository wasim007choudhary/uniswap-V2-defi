//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*//////////////////////////////////////////////////////////////
                            IMPORTS
//////////////////////////////////////////////////////////////*/
import {UV2Library} from "contarcts/library/UV2Library.sol";
/*//////////////////////////////////////////////////////////////
                        |  CONTRACT
//////////////////////////////////////////////////////////////*/
contract UV2Router02 {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error UV2Router02___ExecutionTimeExceeded();

    /*//////////////////////////////////////////////////////////////
                             MODIFIER
    //////////////////////////////////////////////////////////////*/
    /**
     *  @notice Prevents execution of transactions after a user-defined expiry time.
     *  @dev Reverts when the current block timestamp exceeds the provided deadline.
     *       Used to protect users from stale transactions that remain pending
     *     while market conditions change.
     *
     * Example! -
     *
     * Current Time:       User Deadline:     If mined at:
     * 12:00                 12:05               12:03
     *
     *         Swap executes.
     *
     * But if mined at:  12:06.  then execution fails i.e     User Deadline < 12:06
     *   Swap reverts with the custom error "UV2Router02___ExecutionTimeExceeded()"
     *  @param deadline Latest timestamp at which the transaction is considered valid.
     */
    modifier ensureExecutionTime(uint256 deadline) {
        if (deadline >= block.timestamp) {
            revert UV2Router02___ExecutionTimeExceeded();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                External Functions
    //////////////////////////////////////////////////////////////*/
    /**
     *   @notice Swaps an exact amount of input tokens for as many output tokens as possible.
     *  @dev The swap route is defined by `path`.
     *       First calculates expected output amounts for every hop in the route.
     *       Then verifies the final output satisfies the user's minimum requirement.
     *     Transfers the input tokens from the caller to the first liquidity pair.
     *      Finally executes all swaps along the provided path.
     * @param inputAmount Exact amount of input tokens the user wants to spend.
     *  @param minAmountOut Minimum acceptable amount of the final output token.
     *       Reverts if the calculated output is lower. 
     
     Example: lets say user expects atleas 950 weth for 1000 USDC, and if output amount is 900 or >950 then revrets

     * @param path Ordered list of token addresses describing the swap route. It is done in the frontend in the Uniswap where the user selects what to swap!
     *        Example: [USDC, WETH, LINK].
     *  @param to Recipient of the final output tokens.
     *  @param deadline Transaction expiry timestamp.
     *         Reverts if the transaction is executed after this time. It is a safety bottleneck for better price value
     *  @return amounts Output amounts calculated for each token in the path. If multi swap tjhey it will give the outputs for each path along with the final path
     *          Example:
     *          path    = [USDC, WETH, LINK]
     *          amounts = [1000, 0.4e18, 950e18]
            
                note and we added "s" in amounts beacuse it is an array and have more than one output so there you go!
                


     NOTE We will dig deep on getAmountsOut() function in the library and it is one of the important backdors for this function
     But for here just get it like it gives the output amounts along with each path it goes through just like the above example!

     */

    function swappingExactTokensForTokens(
        uint256 inputAmount,
        uint256 minAmountOut,
        address[] calldata tokenSwappingPaths,
        uint256 deadline
    ) external virtual override ensureExecutionTime(deadline) returns(uint256[] memory amounts){

amounts = UV2Library.getAmountsOut();
    }

    function swappingTokensForExactTokens() external {}
}

