//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*//////////////////////////////////////////////////////////////
                            IMPORTS
//////////////////////////////////////////////////////////////*/
import {UV2Library} from "contracts/peripheryUV2/library/UV2Library.sol";
import {IUV2Router02} from "contracts/peripheryUV2/Interfaces/IUV2Router02.sol";
import {IUV2Pair} from "contracts/coreUV2/Interface/IUV2Pair.sol";
import {MyTransferHelper} from "contracts/peripheryUV2/library/WTransferHelper.sol";

import {IERC20} from "contracts/peripheryUV2/Interfaces/IERC20.sol";

import {IUV2Factory} from "contracts/coreUV2/Interface/IUV2Factory.sol";

/*//////////////////////////////////////////////////////////////
                        |  CONTRACT
//////////////////////////////////////////////////////////////*/
contract UV2Router02 is IUV2Router02 {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error UV2Router02___ExecutionTimeExceeded();
    error UV2Router02___swappingExactTokensForTokens__MinimumOutLimitputNotMet();
    error UV2Router___swapTokensForExactTokens__MaximumInputAmountLimitExceeded();
    error UV2Router___swapExactTokensForTokensSupportingFeeOnTransferTokens___OutputAmountBelowUserMinimumLimit();
    error UV2Router02___addLiquidity__PairDoesNotExist();
    error UV2Router02___addLiquidity___InsufficientBOptimal_AmountBelowMin();
    error UV2Router02___addLiquidity___InsufficientAOptimal_AmountBelowMin();
    error UV2Router02___removeLiquidity__AmountAIsLessThanMinimumRequiredAsked();
    error UV2Router02___removeLiquidity__AmountBIsLessThanMinimumRequiredAsked();

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

    /*//////////////////////////////////////////////////////////////
                             Adding lIQUIDITY FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /**
     * @notice Computes the optimal token amounts to add as liquidity while preserving the current pool ratio.
     *
     * @dev
     * - Creates the Pair contract if it does not already exist.
     * - If the pool has no liquidity (both reserves are zero), the desired token amounts are used directly since no reserve ratio exists yet.
     * - For existing pools, the function calculates the optimal deposit amounts using the current reserve ratio so that adding liquidity does not change the pool price.
     * - The Router first attempts to use the entire desired amount of Token A and computes the required amount of Token B.
     * - If the caller cannot supply enough Token B, the Router instead uses the entire desired amount of Token B and computes the required amount of Token A.
     * - The computed deposit amounts are returned and are intended to be transferred to the Pair contract by the caller.
     * - The assertion verifies an internal mathematical invariant: after switching to the Token B path, the required Token A amount must never exceed the caller's desired maximum Token A amount.
     *
     * @param tokenA Address of the first ERC20 token in the liquidity pair.
     * @param tokenB Address of the second ERC20 token in the liquidity pair.
     * @param amountADesiredMaxInput Maximum amount of Token A the caller is willing to deposit.
     * @param amountBDesiredMaxInput Maximum amount of Token B the caller is willing to deposit.
     * @param amountAMinDeposit Minimum acceptable amount of Token A that must actually be deposited, otherwise the transaction reverts.
     * @param amountBMinDeposit Minimum acceptable amount of Token B that must actually be deposited, otherwise the transaction reverts.
     *
     * @return amountA The final amount of Token A that should be transferred to the Pair contract.
     * @return amountB The final amount of Token B that should be transferred to the Pair contract.
     *
     * @custom:reverts UV2Router02___addLiquidity___InsufficientBOptimal_AmountBelowMin
     * Reverts if the optimal Token B amount required to preserve the current reserve ratio is less than the caller's minimum acceptable Token B deposit.
     *
     * @custom:reverts UV2Router02___addLiquidity___InsufficientAOptimal_AmountBelowMin
     * Reverts if the optimal Token A amount required to preserve the current reserve ratio is less than the caller's minimum acceptable Token A deposit.
     *
     * @custom:reverts Panic(0x01)
     * Reverts if the internal mathematical invariant `amountAOptimal <= amountADesiredMaxInput` is violated.
     * This should never occur during correct execution and indicates a bug in the Router logic rather than invalid user input.
     *
     * -------------------------------------------------------------------------------------------------------------------------------------------------------
     * @custom:see For a complete, in-depth dissection:
     * 1. First, go through the conceptual foundation → `notes/Liquidity/1. Conceptual_and_MathematicalFoundation/`
     * 2. Then, study the contract flow → `notes/Liquidity/2.Code_Implementation/AddLiq_Mint/P1-AddLiq_Mint_ContractFlow.md`
     * 3. Finally, dive into this internal function here → `notes/Liquidity/2.Code_Implementation/AddLiq_Mint/P2-Router02_internal_addLiquidity().md`
     *  ----------------------------------------------------------------------------------------------------------------------------------------------------------
     */
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesiredMaxInput, // "MAX TokenA I am willing  to deposit"
        uint256 amountBDesiredMaxInput, // "MAX TokenB I am willing to deposit"
        uint256 amountAMinDeposit, // Minimum deposit at least this much Token A or revert
        uint256 amountBMinDeposit // Minimum deposit at least this much Token B or revert
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        if (IUV2Factory(i_factory).getPair(tokenA, tokenB) == address(0)) {
            IUV2Factory(i_factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = UV2Library.getReserves(i_factory, tokenA, tokenB);

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesiredMaxInput, amountBDesiredMaxInput);
        } else {
            uint256 amountBOptimal = UV2Library.quote(amountADesiredMaxInput, reserveA, reserveB);
            if (amountBOptimal <= amountBDesiredMaxInput) {
                if (amountBOptimal < amountBMinDeposit) {
                    revert UV2Router02___addLiquidity___InsufficientBOptimal_AmountBelowMin();
                }
                (amountA, amountB) = (amountADesiredMaxInput, amountBOptimal);
            } else {
                uint256 amountAOptimal = UV2Library.quote(amountBDesiredMaxInput, reserveB, reserveA);
                assert(amountAOptimal <= amountADesiredMaxInput);
                if (amountAOptimal < amountAMinDeposit) {
                    revert UV2Router02___addLiquidity___InsufficientAOptimal_AmountBelowMin();
                }
                (amountA, amountB) = (amountAOptimal, amountBDesiredMaxInput);
            }
        }
    }

    /**
     * @notice Adds liquidity to a token pair by computing the optimal deposit amounts and transferring the tokens into the Pair contract.
     *
     * @dev
     * - Delegates to {_addLiquidity} to determine the optimal Token A and Token B amounts while preserving the current pool reserve ratio.
     * - Creates the Pair contract if it does not already exist (performed internally by {_addLiquidity}).
     * - Transfers the computed token amounts directly from the caller to the Pair contract using `transferFrom`.
     * - The Router never temporarily holds the user's tokens; they move directly from the caller to the Pair contract.
     * - Once both transfers complete, the Pair contract contains the deposited liquidity and is ready to mint LP tokens.
     * @dev Calls `Pair.mint(to)` to mint LP tokens, update the Pair's reserves, perform protocol fee accounting (if enabled), and finalize the liquidity addition.
     *
     * @param tokenA Address of the first ERC20 token in the liquidity pair.
     * @param tokenB Address of the second ERC20 token in the liquidity pair.
     * @param amountADesiredMaxInput Maximum amount of Token A the caller is willing to deposit.
     * @param amountBDesiredMaxInput Maximum amount of Token B the caller is willing to deposit.
     * @param amountAMinDeposit Minimum acceptable amount of Token A that must actually be deposited after optimal ratio calculation.
     * @param amountBMinDeposit Minimum acceptable amount of Token B that must actually be deposited after optimal ratio calculation.
     * @param to Address that will ultimately receive the minted LP tokens once `Pair.mint()` is executed.
     * @param deadline Unix timestamp after which the transaction becomes invalid and will revert.
     *
     * @return amountA The actual amount of Token A transferred into the Pair contract.
     * @return amountB The actual amount of Token B transferred into the Pair contract.
     * @return liquidity The amount of LP tokens minted by the Pair contract. This value is assigned after `Pair.mint()` executes.
     *
     * @custom:reverts UV2Router02___ExecutionTimeExceeded
     * Reverts if the current block timestamp exceeds the specified `deadline`.
     *
     * @custom:reverts UV2Router02___addLiquidity___InsufficientBOptimal_AmountBelowMin
     * Propagated from {_addLiquidity} if the optimal Token B amount required to preserve the reserve ratio is below the caller's minimum acceptable Token B deposit.
     *
     * @custom:reverts UV2Router02___addLiquidity___InsufficientAOptimal_AmountBelowMin
     * Propagated from {_addLiquidity} if the optimal Token A amount required to preserve the reserve ratio is below the caller's minimum acceptable Token A deposit.
     *
     * @custom:reverts Panic(0x01)
     * Propagated from {_addLiquidity} if the internal mathematical invariant of the optimal liquidity calculation is violated. This indicates a bug in the Router logic rather than invalid user input.
     *
     * @custom:reverts TrasnferHelper__safeTransferFrom__TransferFromNotSuccessful or TrasnferHelper__safeTransferFrom__TokenReturnData_TransferFromFailed
     * Reverts if either ERC20 `transferFrom` operation fails, typically due to insufficient allowance, insufficient balance, or a non-compliant token implementation or Returning false on transfer.
     *
     * -------------------------------------------------------------------------------------------------------------------------------------------------------
     * @custom:see For a complete, in-depth dissection:
     * 1. First, go through the conceptual foundation → `notes/Liquidity/1.Conceptual_and_MathematicalFoundation/`
     * 2. Then, study the contract flow → `notes/Liquidity/2.Code_Implementation/AddLiq_Mint/P1-AddLiq_Mint_ContractFlow.md`
     * 3. Finally, dive into this internal function here → `notes/Liquidity/2.Code_Implementation/AddLiq_Mint/P2-notes/Liquidity/2. Code_Implementation/AddLiq_Mint/P3-Router02_external_addLiquidity/p3.1-ExecutingTheLiquidityAddition.md`
     *  ----------------------------------------------------------------------------------------------------------------------------------------------------------
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesiredMaxInput,
        uint256 amountBDesiredMaxInput,
        uint256 amountAMinDeposit,
        uint256 amountBMinDeposit,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensureExecutionTime(deadline)
        returns (uint256 amountA, uint256 amountB, uint256 liquidity)
    {
        (amountA, amountB) = _addLiquidity(
            tokenA, tokenB, amountADesiredMaxInput, amountBDesiredMaxInput, amountAMinDeposit, amountBMinDeposit
        );
        address pair = UV2Library.pairFor(i_factory, tokenA, tokenB);
        MyTransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        MyTransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);

        liquidity = IUV2Pair(pair).mint(to);
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /**
     * @notice Removes liquidity from a Uniswap V2 Pair and redeems the
     *         underlying assets.
     *
     * @dev This function coordinates the liquidity removal process but does
     *      not perform the redemption itself. The actual LP token burning,
     *      proportional asset calculation, reserve updates, and protocol fee
     *      handling are delegated to the Pair contract.
     *
     *      High-level workflow:
     *
     *      1. Verifies the transaction has not expired.
     *      2. Computes the deterministic Pair contract address for the
     *         supplied token pair.
     *      3. Transfers the specified LP tokens from the caller to the Pair
     *         contract.
     *      4. Calls `Pair.burn()` to:
     *         - Burn the transferred LP tokens.
     *         - Calculate the user's proportional share of the pool.
     *         - Transfer the underlying assets to the recipient.
     *      5. Restores the returned token amounts to match the user's
     *         requested `tokenA` / `tokenB` ordering.
     *      6. Verifies the redeemed amounts satisfy the user's minimum
     *         acceptable output constraints.
     *
     *      The Router itself never:
     *      - Calculates redemption amounts.
     *      - Burns LP tokens.
     *      - Updates Pair reserves.
     *
     *      Those responsibilities belong entirely to the Pair contract.
     *
     * @param tokenA One of the two tokens in the liquidity pool.
     * @param tokenB The second token in the liquidity pool.
     * @param liquidity The amount of LP tokens to redeem.
     * @param amountAMin The minimum acceptable amount of `tokenA` that must
     *                   be received, otherwise the transaction reverts.
     * @param amountBMin The minimum acceptable amount of `tokenB` that must
     *                   be received, otherwise the transaction reverts.
     * @param to The address that will receive the redeemed underlying
     *           assets. This does not have to be `msg.sender`.
     * @param deadline The latest timestamp at which this transaction may be
     *                 executed.
     *
     * @return amountA The amount of `tokenA` redeemed from the Pair.
     * @return amountB The amount of `tokenB` redeemed from the Pair.
     *
     * @custom:reverts UV2Router02___removeLiquidity__AmountAIsLessThanMinimumRequiredAsked
     * Reverts if the redeemed amount of `tokenA` is less than
     * `amountAMin`.
     *
     * @custom:reverts UV2Router02___removeLiquidity__AmountBIsLessThanMinimumRequiredAsked
     * Reverts if the redeemed amount of `tokenB` is less than
     * `amountBMin`.
     *
     * @custom:security LP tokens are transferred to the Pair before calling
     *                  `burn()` so the Pair can securely redeem and destroy
     *                  the ownership tokens itself.
     *
     * @custom:security Returned amounts are reordered from the Pair's
     *                  internal `token0` / `token1` ordering back into the
     *                  user-requested `tokenA` / `tokenB` ordering before
     *                  being returned.
     *  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     *  @custom:see for complete dissection and a detailed breakdown:
     *  1. First, go through the conceptual foundation → `notes/Liquidity/1.Conceptual_and_MathematicalFoundation/` all better understand the math and concepts behind liquidity addition and removal
     *  2. Then go here → notes/Liquidity/1. Conceptual_and_MathematicalFoundation/P5-BurnSharesFormulaMathematical.md***,
     *  3. and Finally go here -> notes/Liquidity/2. Code_Implementation/RemoveLiq_Burn/Router02_removeLiquidity
     *  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external virtual override ensureExecutionTime(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = UV2Library.pairFor(i_factory, tokenA, tokenB);
        IUV2Pair(pair).transferFrom(msg.sender, pair, liquidity);

        (uint256 amount0, uint256 amount1) = IUV2Pair(pair).burn(to);
        (address token0,) = UV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        if (amountA < amountAMin) {
            revert UV2Router02___removeLiquidity__AmountAIsLessThanMinimumRequiredAsked();
        }
        if (amountB < amountBMin) {
            revert UV2Router02___removeLiquidity__AmountBIsLessThanMinimumRequiredAsked();
        }
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
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
            IUV2Pair(UV2Library.pairFor(i_factory, input, output)).swap(amount0out, amount1out, _to, new bytes(0));
        }
    }

    /*/////////////////////////////////////////////////////////////
                               External Functions
    //////////////////////////////////////////////////////////////*/

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /**
     * @notice Swaps an exact amount of input tokens for as many output tokens as possible.
     * @dev The swap route is defined by `path`.
     *      First calculates the expected output amounts for every hop in the route.
     *      Then verifies the final output satisfies the user's minimum acceptable amount.
     *      Transfers the input tokens from the caller to the first liquidity pair.
     *      Finally executes all swaps along the provided path.
     *
     * @param inputAmount Exact amount of input tokens the user wants to spend.
     *
     * @param minAmountOut Minimum amount of output tokens the user is willing to receive.
     *        Think of it as the user's minimum acceptable return.
     *        Reverts if the final output amount is less than this value.
     *
     *        Example:
     *        User swaps exactly 1000 USDC.
     *        minAmountOut = 950 LINK.
     *        If the final output is 980 LINK, the swap succeeds.
     *        If the final output is 900 LINK, the transaction reverts.
     *
     * @param path Ordered list of token addresses describing the swap route.
     *        It is created by the frontend (e.g., Uniswap Interface) based on the tokens selected by the user.
     *
     *        Example:
     *        [USDC, WETH, LINK]
     *
     * @param to Recipient of the final output tokens.
     *
     * @param deadline Transaction expiry timestamp.
     *        Reverts if the transaction is executed after this time.
     *        This protects users from executing swaps using stale prices.
     *
     * @return amounts Array containing the calculated output amounts for every hop in the swap path.
     *
     *        Example:
     *        path    = [USDC, WETH, LINK]
     *        amounts = [1000e6, 0.4e18, 950e18]
     *
     *        Here:
     *        - 1000 USDC is provided as the exact input.
     *        - It swaps into 0.4 WETH.
     *        - Finally producing 950 LINK.
     *
     *        Note: `amounts` is plural because it is an array containing the token amount for
     *        every hop in the swap path, not just the final output amount.
     *
     * @custom:reverts UV2Router___ExecutionDeadlineExceeded
     *         If the transaction is executed after `deadline`.
     *
     * @custom:reverts UV2Router02___swappingExactTokensForTokens__MinimumOutLimitputNotMet
     *         If the final output amount is less than `minAmountOut`.
     *
     *--------------------------------------------------------------------------------------------
     * @custom:note
     * Before reading this function, it is recommended to first understand the NatSpecs of
     * `getAmountOut()`, `getAmountsOut()`, `pairFor()`, `getReserves()`, and their related helper
     * functions as well, as this function relies on them to calculate the output amounts. And
     *  When you hit the line `_swap ` do that as well!
     *--------------------------------------------------------------------------------------------
     */

    function swapExactTokensForTokens(
        uint256 inputAmount,
        uint256 minAmountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensureExecutionTime(deadline) returns (uint256[] memory amounts) {
        amounts = UV2Library.getAmountsOut(i_factory, inputAmount, path);
        if (amounts[amounts.length - 1] < minAmountOut) {
            revert UV2Router02___swappingExactTokensForTokens__MinimumOutLimitputNotMet();
        }
        MyTransferHelper.safeTransferFrom(
            path[0], msg.sender, UV2Library.pairFor(i_factory, path[0], path[1]), amounts[0]
        );
        ///@custom:see _swap see the function natspec and also notes/Periphery/Library/routert/_swap.md to understand what this below function does
        _swap(path, to, amounts);
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /**
     * @notice Swaps the minimum required amount of input tokens for an exact amount of output tokens.
     * @dev The swap route is defined by `path`.
     *      First calculates the minimum input amounts required for every hop in the route.
     *      Then verifies the required input does not exceed the user's maximum spending limit.
     *      Transfers only the required input tokens from the caller to the first liquidity pair.
     *      Finally executes all swaps along the provided path.
     *
     * @param maxAmountIn Maximum amount of input tokens the user is willing to spend.
     *    Think of it as the user's spending limit.
     *    If more input tokens are required than this limit, the transaction reverts.
     *
     *        Example:
     *        User wants exactly 950 LINK.
     *        maxAmountIn = 1000 USDC.
     *        If the router calculates that 980 USDC is required, the swap succeeds.
     *        If it calculates that 1020 USDC is required, the transaction reverts.
     *
     * @param outputAmount Exact amount of the final output token the user wants to receive.
     *        Unlike `swapExactTokensForTokens`, here the output is fixed and the input is calculated.
     *
     * @param path Ordered list of token addresses describing the swap route.
     *        It is created by the frontend (e.g., Uniswap Interface) based on the tokens selected by the user.
     *
     *        Example:
     *        [USDC, WETH, LINK]
     *
     * @param to Recipient of the final output tokens.
     *
     * @param deadline Transaction expiry timestamp.
     *        Reverts if the transaction is executed after this time.
     *        This protects users from executing swaps using stale prices.
     *
     * @return amounts Array containing the calculated token amounts required for every hop in the swap path.
     *
     *        Example:
     *        path    = [USDC, WETH, LINK]
     *        amounts = [1000e6, 0.4e18, 950e18]
     *
     *        Here:
     *        - 1000 USDC is required as the input.
     *        - It swaps into 0.4 WETH.
     *        - Finally producing exactly 950 LINK.
     *
     *        Note: `amounts` is plural because it is an array containing the token amount for
     *        every hop in the swap path, not just the final output amount.
     *
     * @custom:reverts UV2Router___ExecutionDeadlineExceeded
     *         If the transaction is executed after the `deadline`.
     *
     * @custom:reverts UV2Router___swapTokensForExactTokens__MaximumInputAmountLimitExceeded
     *         If the required input amount exceeds `maxAmountIn`.
     *--------------------------------------------------------------------------------------------
     * @custom:note
     * Before reading this function, it is recommended to first understand the NatSpecs of
     * `getAmountIn()`, `getAmountsIn()`, `pairFor()`, `getReserves()`, and their related helper
     * functions as well, as this function relies on them to calculate the required input amounts. And
     * When you hit the line _swap do that as well!
     *--------------------------------------------------------------------------------------------
     */

    function swapTokensForExactTokens(
        uint256 maxAmountIn,
        uint256 outputAmount,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensureExecutionTime(deadline) returns (uint256[] memory amounts) {
        amounts = UV2Library.getAmountsIn(i_factory, outputAmount, path);
        if (amounts[0] > maxAmountIn) {
            revert UV2Router___swapTokensForExactTokens__MaximumInputAmountLimitExceeded();
        }
        MyTransferHelper.safeTransferFrom(
            path[0], msg.sender, UV2Library.pairFor(i_factory, path[0], path[1]), amounts[0]
        );
        ///@custom:see _swap see the function natspec and also notes/Periphery/Library/routert/_swap.md to understand what this below function does
        _swap(path, to, amounts);
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /**
     * @notice Routes a swap through one or more Uniswap V2 Pairs while supporting
     *         fee-on-transfer (tax/burn/reflection) tokens.
     *
     * @dev This function is the Router's execution engine for fee-on-transfer tokens.
     *
     * Before entering `_swapSupportingFeeOnTransferTokens()`:
     * * The public function has already transferred the user's input tokens
     *   to the first Pair.
     * * The first Pair already holds the input tokens
     *   (after any transfer fee deducted by the token contract).
     * * The Pair's stored reserves have NOT yet been updated.
     *
     * Unlike the normal `_swap()`, this function does NOT trust that the Pair
     * received exactly the transferred input amount.
     *
     * Instead, for every hop it:
     * * Reads the Pair's reserves.
     * * Measures the Pair's actual received input amount.
     * * Calculates the correct output amount using the measured input.
     * * Translates Router language (input/output)
     *   into Pair language (token0/token1).
     * * Determines where the current output should be sent.
     * * Invokes `Pair.swap()` for each hop.
     *
     * For multi-hop swaps, intermediate outputs are sent directly from one Pair
     * to the next Pair without passing through the Router.
     *
     * Mental Model:
     *
     * balanceOf(pair) - reserveInput = Measure Actual Input
     *
     * getAmountOut() = Pricing Engine
     *
     * Pair.swap() = Execution Engine
     *
     * Router measures.
     * Router calculates.
     * Pair enforces.
     *
     * @param path Ordered sequence of token addresses describing
     *        the swap route.
     *
     *        Example:
     *        [USDC, WETH, LINK]
     *
     * @param to Final recipient of the last output token.
     *
     * @custom:routing
     * If another hop exists:
     *
     * Current Pair ==> Next Pair
     *
     * Otherwise:
     *
     * Current Pair ==> Final Recipient
     *
     * @custom:note
     * Unlike `_swap()`, this function cannot rely on pre-calculated amounts
     * because fee-on-transfer tokens may deduct tokens during transfer.
     *
     * Therefore, each Pair's actual received input amount is measured using:
     *
     * ```
     * IERC20(input).balanceOf(address(pair)) - reserveInput
     * ```
     *
     * before calculating the output amount for that hop.
     *
     * @custom:see
     * For a complete line-by-line breakdown see:
     * `notes/Periphery/router/_swapSupportingFeeOnTransferTokens.md`
     */
    function _swapSupportingFeeOnTransferTokens(address[] calldata path, address to) internal {
        for (uint256 i = 0; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UV2Library.sortTokens(input, output);
            IUV2Pair pair = IUV2Pair(UV2Library.pairFor(i_factory, input, output));

            uint256 amountIn;
            uint256 amountOut;

            {
                (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
                (uint256 reserveIn, uint256 reserveOut) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

                amountIn = IERC20(input).balanceOf(address(pair)) - reserveIn;
                amountOut = UV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
            }
            (uint256 amount0out, uint256 amount1out) =
                input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address _to = i < path.length - 2 ? UV2Library.pairFor(i_factory, output, path[i + 2]) : to;
            pair.swap(amount0out, amount1out, _to, new bytes(0));
        }
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /**
     * @notice Swaps an exact amount of input tokens for as many output tokens as possible while supporting
     *         fee-on-transfer (tax/burn/reflection) tokens.
     *
     * @dev Unlike `swapExactTokensForTokens`, this function cannot pre-calculate the output amounts because
     *      fee-on-transfer tokens may deduct a portion of the transferred tokens before they reach the Pair.
     *
     *      The function first transfers the exact input tokens from the caller directly to the first
     *      liquidity Pair. It then records the recipient's current balance of the final output token,
     *      executes all swaps while measuring the actual input received by each Pair, and finally verifies
     *      that the recipient received at least the minimum output amount specified by the user.
     *
     * @param inputAmount Exact amount of input tokens the user wants to spend.
     *        This amount is transferred from the caller to the first liquidity Pair.
     *
     *        Note:
     *        If the input token charges a transfer fee, the Pair may receive fewer tokens than
     *        `inputAmount`.
     *
     * @param minOutputAmount Minimum acceptable amount of the final output token the recipient must receive.
     *        If the actual received amount is lower than this value, the entire transaction reverts.
     *
     * @param path Ordered list of token addresses describing the swap route.
     *        It is created by the frontend (e.g., Uniswap Interface) based on the tokens selected by the user.
     *
     *        Example:
     *        [USDC, WETH, LINK]
     *
     * @param to Recipient of the final output tokens.
     *
     * @param deadline Transaction expiry timestamp.
     *        Reverts if the transaction is executed after this time.
     *        This protects users from executing swaps using stale prices.
     *
     * @custom:reverts UV2Router___ExecutionDeadlineExceeded
     *         If the transaction is executed after the `deadline`.
     *
     * @custom:reverts UV2Router___swapExactTokensForTokensSupportingFeeOnTransferTokens___OutputAmountBelowUserMinimumLimit
     *         If the recipient receives fewer output tokens than `minOutputAmount`.
     *
     *--------------------------------------------------------------------------------------------------
     *
     * @custom:note visit notes/Periphery/Library/routert/swapExactTokensForTokensSupportingFeeOnTransferTokens.md for complete dissection!
     *
     * When execution reaches `_swapSupportingFeeOnTransferTokens()`, read its NatSpecs as well,
     * since that function contains the core swap logic for fee-on-transfer tokens.
     *--------------------------------------------------------------------------------------------------
     */
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 inputAmount,
        uint256 minOutputAmount,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensureExecutionTime(deadline) {
        MyTransferHelper.safeTransferFrom(
            path[0], msg.sender, UV2Library.pairFor(i_factory, path[0], path[1]), inputAmount
        );
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        if (IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore < minOutputAmount) {
            revert UV2Router___swapExactTokensForTokensSupportingFeeOnTransferTokens___OutputAmountBelowUserMinimumLimit();
        }
    }

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

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    function getAmountsOut(uint256 amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return UV2Library.getAmountsOut(i_factory, amountIn, path);
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        virtual
        override
        returns (uint256 amountIn)
    {
        return UV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    function getAmountsIn(uint256 amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return UV2Library.getAmountsIn(i_factory, amountOut, path);
    }

    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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

