//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*//////////////////////////////////////////////////////////////
                            IMPORTS
//////////////////////////////////////////////////////////////*/
import {UV2Library} from "contracts/peripheryUV2/library/UV2Library.sol";
import {IUV2Router02} from "contracts/peripheryUV2/Interfaces/IUV2Router02.sol";
import {IUV2Pair} from "contracts/coreUV2/Interface/IUV2Pair.sol";
import {MyTransferHelper} from "contracts/peripheryUV2/library/WTransferHelper.sol";

/*//////////////////////////////////////////////////////////////
                        |  CONTRACT
//////////////////////////////////////////////////////////////*/
contract UV2Router02 is IUV2Router02 {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error UV2Router02___ExecutionTimeExceeded();
    error UV2Router02___swappingExactTokensForTokens__InsufficientOutputAmount();

    /*//////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    address public immutable i_factory;

    constructor(address _factory) {
        i_factory = _factory;
    }

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
        if (block.timestamp > deadline) {
            revert UV2Router02___ExecutionTimeExceeded();
        }
        _;
    }
    /**
     *
     * @notice Routes a swap through one or more Uniswap V2 Pairs.
     *
     * @dev This function is the Router's execution engine.
     *
     * Before entering `_swap()`:
     * * Output amounts have already been calculated.
     * * Slippage checks have already passed.
     * * The initial input tokens have already been transferred
     * to the first Pair.
     *
     * `_swap()` does NOT:
     * * Calculate prices.
     * * Calculate output amounts.
     * * Collect user tokens.
     *
     * Instead it:
     * * Iterates through the swap path.
     * * Determines the current Pair.
     * * Translates Router language (input/output)
     * into Pair language (token0/token1).
     * * Determines where the current output should be sent.
     * * Invokes `Pair.swap()` for each hop.
     *
     * For multi-hop swaps, intermediate outputs are sent
     * directly from one Pair to the next Pair without
     * passing through the Router.
     *
     * Mental Model:
     *
     * getAmountsOut()
     * ```
     *   = Pricing Engine
     *   ```
     *
     * _swap()
     * ```
     *   = Routing Engine
     *   ```
     *
     * Pair.swap()
     * ```
     *   = Execution Engine
     *   ```
     *
     * Router calculates.
     * Pair enforces.
     *
     * @param path Ordered sequence of tokens describing
     * the swap route.
     *
     * Example:
     * [USDC, WETH, LINK]
     *
     * @param to Final recipient of the last output token.
     *
     * @param amounts Pre-calculated swap amounts where:
     * * amounts[0] is the user input amount.
     * * amounts[i + 1] is the expected output of hop i.
     *
     * @custom:routing
     * If another hop exists:
     *
     * Current Pair
     * ```
     *   ↓
     *   ```
     * Next Pair
     *
     * Otherwise:
     *
     * Current Pair
     * ```
     *   ↓
     *   ```
     * Final Recipient
     *
     * @custom:note
     * The final line:
     *
     * IUV2Pair(
     * ```
     *   UV2Library.pairFor(
     *   ```
     * ```
     *       i_factory,
     *   ```
     * ```
     *       input,
     *   ```
     * ```
     *       output
     *   ```
     * ```
     *   )
     *   ```
     * ).swap(
     * ```
     *   amount0out,
     *   ```
     * ```
     *   amount1out,
     *   ```
     * ```
     *   _to,
     *   ```
     * ```
     *   new bytes(0)
     *   ```
     * );
     *
     * transfers control from the Router to the Pair.
     *
     * At that moment the Router's job is complete and
     * swap execution continues inside `Pair.swap()`.
     *
     * @custom:see For a complete line-by-line breakdown see: notes/Periphery/router/_swap.md
     */

    function _swap(address[] memory path, address to, uint256[] memory amounts) internal {
        for (uint256 i = 0; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UV2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0out, uint256 amount1out) =
                input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address _to = i < path.length - 2 ? UV2Library.pairFor(i_factory, output, path[i + 2]) : to;
            ///@custom:see  for next IUV2pair.swap  see notes notes/Core/UV2Pair--swap.md for complete dissection
            IUV2Pair(UV2Library.pairFor(i_factory, input, output)).swap(amount0out, amount1out, to, new bytes(0));
        }
    }

    /*/////////////////////////////////////////////////////////////
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
     *
     *  Example: lets say user expects atleas 950 weth for 1000 USDC, and if output amount is 900 or >950 then revrets
     *
     * @param path Ordered list of token addresses describing the swap route. It is done in the frontend in the Uniswap where the user selects what to swap!
     *        Example: [USDC, WETH, LINK].
     *  @param to Recipient of the final output tokens.
     *  @param deadline Transaction expiry timestamp.
     *         Reverts if the transaction is executed after this time. It is a safety bottleneck for better price value
     *  @return amounts Output amounts calculated for each token in the path. If multi swap tjhey it will give the outputs for each path along with the final path
     *          Example:
     *          path    = [USDC, WETH, LINK]
     *          amounts = [1000, 0.4e18, 950e18]
     *
     *             note and we added "s" in amounts beacuse it is an array and have more than one output so there you go!
     *
     *
     *
     *  NOTE We will dig deep on getAmountsOut() function in the library and it is one of the important backdors for this function
     *  But for here just get it like it gives the output amounts along with each path it goes through just like the above example!
     *
     */

    function swappingExactTokensForTokens(
        uint256 inputAmount,
        uint256 minAmountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensureExecutionTime(deadline) returns (uint256[] memory amounts) {
        amounts = UV2Library.getAmountsOut(i_factory, inputAmount, path);
        if (amounts[amounts.length - 1] < minAmountOut) {
            revert UV2Router02___swappingExactTokensForTokens__InsufficientOutputAmount();
        }
        MyTransferHelper.safeTrasnferFrom(
            path[0], msg.sender, UV2Library.pairFor(i_factory, path[0], path[1]), amounts[0]
        );
        // dissection _swap
    }

    //function swappingTokensForExactTokens() external {}

    /*/////////////////////////////////////////////////////////////////////////////////////
                               UV2LIBRARY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////////////////*/

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        virtual
        override
        returns (uint256 amountOut)
    {
        return UV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountsOut(uint256 amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return UV2Library.getAmountsOut(i_factory, amountIn, path);
    }

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        virtual
        override
        returns (uint256 amountIn)
    {
        return UV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return UV2Library.getAmountsIn(i_factory, amountOut, path);
    }

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB)
        public
        pure
        virtual
        override
        returns (uint256 amountB)
    {
        return UV2Library.quote(amountA, reserveA, reserveB);
    }
}

