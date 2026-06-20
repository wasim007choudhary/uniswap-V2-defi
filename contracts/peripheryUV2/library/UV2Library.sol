//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

 /*//////////////////////////////////////////////////////////////
                                IMPORTS
    //////////////////////////////////////////////////////////////*/
    import {IUV2Pair} from "contracts/coreUV2/Interface/IUV2Pair.sol";
library UV2Library {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error UV2Library__getAmountOut__InsufficientInputAmount();
    error UV2Library__getAmountOut__InsufficientLiquidity();
    error UV2Library__getAmountsOut__InvalidPath();
    error UV2Library__sortaTokens__Identical_Address();
    error UV2Library__sortTokens__Invalid_Token0_Address();

    /*//////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Calculates the maximum output amount for a given input amount.
     *
     * @dev Uses Uniswap V2's constant product AMM formula (x * y = k) while
     * accounting for the 0.3% swap fee.
     *
     * Formula:
     *
     *     amountOut =
     *         (reserveOut * amountIn * 997)
     *         ----------------------------------
     *         (reserveIn * 1000 + amountIn * 997)
     *
     * The values 997 and 1000 represent Uniswap's 0.3% fee:
     *
     *     0.997 = 997 / 1000
     *
     * Solidity does not support floating-point arithmetic, so the fee-adjusted
     * input amount is represented using integer math.
     *
     * @param  inputAmount Amount of input tokens being swapped.
     * @param reserveIn Current reserve of the input token.
     * @param reserveOut Current reserve of the output token.
     *
     * @return outputAmount Maximum amount of output tokens obtainable for the
     * given input amount.
     * ---------------------------------
     * @dev getAmountOut() only performs the swap calculation for a SINGLE pair.
     *
     * Examples:
     *
     *     WETH -> USDC
     *     WBTC -> DAI
     *
     * Multi-hop paths such as:
     *
     *     WETH -> WBTC -> USDC
     *
     * are handled by getAmountsOut(), which repeatedly calls getAmountOut()
     * for each pair in the path.
     */
    function getAmountOut(uint256 inputAmount, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 outputAmount)
    {
        if (inputAmount <= 0) {
            revert UV2Library__getAmountOut__InsufficientInputAmount();
        }
        if (reserveIn <= 0 || reserveOut <= 0) {
            revert UV2Library__getAmountOut__InsufficientLiquidity();
        }
        /**
         *
         * @dev Understanding Where Uniswap V2's  calculation  dx = (X₀ * dy * 0.997) / (Y₀ + dy * 0.997)
         *
         * ---
         * Example Values
         * ---
         *
         * Assume:
         *
         * ```
         * reserveIn  (X₀) = 100 ETH
         * ```
         * ```
         * reserveOut (Y₀) = 200000 USDC
         * ```
         * ```
         * inputAmount   (dx) = 10 ETH
         * ```
         * ```
         * fee              = 0.3%
         * ```
         *
         * ---
         * Step 1: Original Formula
         * ---
         *
         * Uniswap's swap output formula is:
         *
         *
         * Y₀ × dx × 0.997
         *  dy = -----------------
         *  X₀ + dx × 0.997
         *
         *
         * Substitute the numbers:
         *
         * 200000 × 10 × 0.997
         *  dy = -------------------
         * 100 + 10 × 0.997
         *
         * Calculate:
         *
         * 1,994,000
         * dy = ---------
         * 109.97
         *
         * dy ≈ 18,132.22
         *
         *
         * ---
         * Step 2: Solidity Cannot Use 0.997
         * ---
         *
         * Solidity only works with integer arithmetic.
         *
         * Therefore Uniswap rewrites:
         *
         *    997
         * 0.997 = ----
         *   1000
         *
         * Substituting:
         *
         * 200000 × 10 × (997/1000)
         * dy = --------------------------
         * 100 + 10 × (997/1000)
         *
         * ---
         * Step 3: Remove the Fraction
         * ---
         *
         * We do not want `/1000` inside the denominator.
         *
         * Therefore multiply BOTH numerator and denominator by 1000.
         *
         * Remember:
         *
         * a      a × 1000
         *     ---  = -----------
         * b      b × 1000
         *
         *
         * This does NOT change the value.
         *
         * Therefore:
         *
         *    200000 × 10 × (997/1000) × 1000
         *     dy = ---------------------------------
         *    (100 + 10 × (997/1000)) × 1000
         *
         * ---
         * Numerator --
         * ---
         *
         * The 1000 cancels:
         *
         * 200000 × 10 × (997/1000) × 1000
         *
         * = 200000 × 10 × 997
         *
         * = 1,994,000,000
         *
         *
         * Notice:
         *
         *
         * THIS is where the numerator's 1000 went. It cancelled.
         *
         * ---
         * Denominator --
         * ---
         *
         *  (100 + 10 × (997/1000)) × 1000
         *
         * Distribute the 1000: Apply the distributive property : (a+b)c = ac+bc
         *
         *  (100 × 1000) + (10 × 997) = 100000 + 9970 = 109970
         *
         *
         * ---
         * Final Form
         * ---
         *
         * We now have:
         *          200000 × 10 × 997
         *  dy = ----------------------
         *          100 × 1000 + 10 × 997
         *
         *
         * Numerically:
         *
         *          1,994,000,000
         *  dy = ---------------
         *           109,970
         *
         *   dy ≈ 18,132.22
         *
         * Exactly the same answer as before.
         *
         * ---
         * Compare To Uniswap V2 Code
         * ---
         *
         * Solidity:
         *
         *  uint inputAmountWithFee = inputAmount * 997;
         *
         * Using our numbers:
         *
         *  10 * 997 = 9970
         * ---
         * Solidity:
         *
         *  uint numerator = inputAmountWithFee * reserveOut;
         *
         * Using our numbers:
         *
         * 9970 * 200000 = 1,994,000,000
         *
         * ---
         * Solidity:
         *
         *  uint denominator = reserveIn * 1000 + inputAmountWithFee;
         * ```
         *
         * Using our numbers:
         *
         * 1000 + 9970 = 109970
         * ---
         *
         * Solidity:
         *
         *  amountOut = numerator / denominator;
         *
         * Using our numbers:
         *
         *  1,994,000,000 / 109970 ≈ 18,132.22
         *
         *
         *
         * ---
         * Key Insight
         * ---
         *
         * The `1000` is NOT an extra fee.
         *
         * It appears because Uniswap replaced:
         *
         * ```
         * 0.997
         * ```
         *
         * with:
         *
         * ```
         * 997/1000
         * ```
         *
         * and then multiplied the ENTIRE fraction by 1000 to eliminate decimal
         * arithmetic.
         * The numerator's 1000 disappears because it cancels with the `/1000`
         * from `997/1000`.
         *
         * The denominator's 1000 survives as:
         *
         * reserveIn * 1000
         *
         * which is why Uniswap's implementation contains:
         *
         * reserveIn.mul(1000).add(inputAmountWithFee)
         *
         * and NOT:
         * reserveOut.mul(1000)
         *
         * Note We will directly use signs for multiply and add unlike in the natspec as uniswap needed to check overflow and
         * underflow but we are doing with solidity version 0.8+ so it automatically does it for us!
         */

        // go through the above natspec completly befreo going any further to the caluclations or you will get lost
        uint256 inputAmountWithFee = inputAmount * 997;
        uint256 numerator = inputAmountWithFee * reserveOut;
        uint256 denominator = inputAmountWithFee + (reserveIn * 1000);
        outputAmount = numerator / denominator;
    }
    /**
    @title getAmountsOut()
 * @notice Calculates the expected output amount at each step of a swap route.
 *
 * @dev Serves as a route pricing engine by simulating swaps across one or more
 *      liquidity pairs without executing any token transfers.
 *
 *      Uses the provided path to determine the swap route and iteratively
 *      calculates the expected output amount for each hop using current pair
 *      reserves and the Uniswap V2 pricing formula.
 *
 *      Supports both:
 *      - Single-hop routes (e.g. USDC -> WETH)
 *      - Multi-hop routes (e.g. USDC -> WETH -> LINK)
 *
 *      The returned array contains the expected token amount corresponding to
 *      each token in the path. The output of one hop becomes the input of the
 *      next hop.
 *
 *      Example:
 *
 *      Path:
 *      [USDC, WETH, LINK]
 *
 *      Input:
 *      1000 USDC
 *
 *      Returned:
 *      [1000 USDC, 0.4 WETH, 950 LINK]
 *
 *      This function is read-only and does not:
 *      - transfer tokens
 *      - execute swaps
 *      - modify reserves
 *      - change protocol state
 *
 * @param factory Address of the factory contract used to locate liquidity pairs.
 * @param inputAmount Amount of the first token being swapped.
 * @param path Ordered list of token addresses representing the swap route.
 *
 * @return amounts Expected token amounts at each step of the route.

 Note Read the Multi-Hop Swap Output Calculator to get the full core of the function! 
 */

    /**
 * @title Multi-Hop Swap Output Calculator
 * 
 * @notice Calculates expected output amounts for each step of a token swap
 *         through multiple liquidity pools along the provided path.
 * 
 * ============================================================================
 * 🎓 THE BIG PICTURE: What This Function Does
 * ============================================================================
 * 
 * Imagine you're trading Pokémon cards through friends. You start with Pikachu,
 * trade it for Charizard, then trade Charizard for Mewtwo. This function 
 * calculates how many cards you'll get at each step BEFORE you actually trade!
 * 
 * It SIMULATES the entire swap route using current pool reserves to give you
 * expected output amounts. It does NOT execute any trades - it only reads data
 * and does math.
 * 
 * ============================================================================
 * 🚂 THE TRAIN ANALOGY: Understanding Path vs Swaps
 * ============================================================================
 * 
 * Consider: path = [TokenA, TokenB, TokenC]
 * 
 *   🟢 PATH (Train Stations):  [TokenA] → [TokenB] → [TokenC]
 *                                 🚉          🚉          🚉
 * 
 *   🔵 SWAPS (Train Journeys): └─Journey 1─┘└─Journey 2─┘
 * 
 *   📊 The Simple Rule:
 *   ┌──────────────┬───────┬──────────────────────────────┐
 *   │ What         │ Count │ Why?                         │
 *   ├──────────────┼───────┼──────────────────────────────┤
 *   │ Tokens       │   3   │ All stations (start to end)  │
 *   │ Swaps        │   2   │ Journeys BETWEEN stations    │
 *   │ Formula      │       │ Swaps = Tokens - 1           │
 *   └──────────────┴───────┴──────────────────────────────┘
 * 
 *   ❌ COMMON MISTAKE: "3 tokens = 3 swaps" ← WRONG!
 *   ✅ CORRECT RULE:   "3 tokens = 2 swaps" ← Number of pairs!
 * 
 * This is why the loop condition is "i < path.length - 1" instead of 
 * "i < path.length". Each iteration processes ONE PAIR of adjacent tokens.
 * 
 * ============================================================================
 * 📋 THE DATA STRUCTURES: Two Arrays Working Together
 * ============================================================================
 * 
 * PATH tells us WHAT token:     path[i]     = token identity (address)
 * AMOUNTS tells us HOW MANY:    amounts[i]  = token quantity (number)
 * 
 * They are PARALLEL ARRAYS synchronized by index:
 * 
 *   ┌───────┬────────────┬──────────────┬─────────────────────────┐
 *   │ Index │ path[i]    │ amounts[i]   │ Meaning                 │
 *   ├───────┼────────────┼──────────────┼─────────────────────────┤
 *   │   0   │ TokenA     │ amountIn     │ Initial input tokens    │
 *   │   1   │ TokenB     │ output_1     │ After first swap        │
 *   │   2   │ TokenC     │ output_2     │ After second swap       │
 *   └───────┴────────────┴──────────────┴─────────────────────────┘
 * 
 *   🧒 Child Analogy: Recipe Card & Shopping List
 *   ┌─────────────────────────┬──────────────────────────┐
 *   │ RECIPE (path)           │ SHOPPING LIST (amounts)  │
 *   ├─────────────────────────┼──────────────────────────┤
 *   │ Step 0: Flour           │ Item 0: 2 cups          │
 *   │ Step 1: Dough           │ Item 1: 1 ball          │
 *   │ Step 2: Cookies         │ Item 2: 12 pieces       │
 *   └─────────────────────────┴──────────────────────────┘
 *   
 *   Same index = Same step! The recipe tells you WHAT, 
 *   the shopping list tells you HOW MUCH.
 * 
 * ============================================================================
 * 🏦 RESERVES BELONG TO PAIRS, NOT TOKENS
 * ============================================================================
 * 
 *   ❌ WRONG THINKING: "The reserve of TokenA"
 *   ✅ CORRECT THINKING: "The reserves of the TokenA/TokenB pair"
 * 
 * There is no such thing as "the reserve of TokenA" by itself.
 * Reserves always belong to a SPECIFIC LIQUIDITY PAIR.
 * 
 *   Example:
 *   ┌─────────────────────────────────────────────┐
 *   │ TokenA/TokenB Pool: 100 TokenA, 200 TokenB  │
 *   │ TokenB/TokenC Pool: 500 TokenB, 1000 TokenC │
 *   └─────────────────────────────────────────────┘
 * 
 * TokenB appears in TWO different pairs with DIFFERENT reserve contexts!
 * The reserve values for TokenB are different in each pair.
 * 
 *   🧒 Child Analogy: Joint Bank Accounts
 *   ┌──────────────────────────────────────────────┐
 *   │ John & Mary's joint account: $100            │
 *   │ Mary & Bob's joint account:   $500           │
 *   └──────────────────────────────────────────────┘
 *   Mary's money depends on WHICH account you check!
 *   Just like TokenB's reserve depends on WHICH pair you query.
 * 
 * ============================================================================
 * 🔗 THE CHAINING MECHANISM: Outputs Become Future Inputs
 * ============================================================================
 * 
 * This is the CORE IDEA behind multi-hop swaps:
 * The output of one swap AUTOMATICALLY becomes the input for the next swap.
 * 
 *   Visual Chain:
 *   ┌────────────────────────────────────────────────────────────┐
 *   │                                                            │
 *   │  amounts[0] = 5 TokenA  (from user's wallet)               │
 *   │       ↓                                                    │
 *   │  [SWAP #1: TokenA → TokenB]                                │
 *   │       ↓                                                    │
 *   │  amounts[1] = 9 TokenB  (output of swap #1)                │
 *   │       ↓                  (automatically input for swap #2) │
 *   │  [SWAP #2: TokenB → TokenC]                                │
 *   │       ↓                                                    │
 *   │  amounts[2] = 25 TokenC (final output!)                    │
 *   │                                                            │
 *   └────────────────────────────────────────────────────────────┘
 * 
 * No one manually inserts the middle values. The loop calculates each output
 * and stores it in the amounts array, where the next iteration finds and uses it.
 * 
 *   🧒 Child Analogy: Daisy Chain of Trades
 *   ┌────────────────────────────────────────────────────────────┐
 *   │ TRADE 1: You give 5 apples → Get 9 bananas                 │
 *   │          Scoreboard: [5 apples, 9 bananas, ?]              │
 *   │                                                            │
 *   │ TRADE 2: You take those 9 bananas → Give to next trader    │
 *   │          You get back 25 cherries!                         │
 *   │          Scoreboard: [5 apples, 9 bananas, 25 cherries]    │
 *   │                                                            │
 *   │ The bananas weren't from your pocket.                      │
 *   │ They came from the FIRST trade!                            │
 *   └────────────────────────────────────────────────────────────┘
 * 
 * ============================================================================
 * 🔄 THE LOOP: How It Works Step By Step
 * ============================================================================
 * 
 * Loop condition: for (uint i; i < path.length - 1; i++)
 * 
 * For path = [TokenA, TokenB, TokenC] with path.length = 3:
 * 
 *   i = 0 → Processes path[0]→path[1] (TokenA→TokenB) → stores in amounts[1]
 *   i = 1 → Processes path[1]→path[2] (TokenB→TokenC) → stores in amounts[2]
 *   i = 2 → STOPS! (2 < 2 is FALSE)
 * 
 * Each iteration accesses path[i] AND path[i+1] SIMULTANEOUSLY.
 * You don't wait for i++ to get the next token - path[i+1] gives it immediately!
 * 
 * ============================================================================
 * 🎬 BEFORE THE LOOP STARTS: Initial Setup
 * ============================================================================
 * 
 *   Assume: amountIn = 5 TokenA, path = [TokenA, TokenB, TokenC]
 * 
 *   Step 1: Create amounts array with same length as path
 *           amounts = new uint[](path.length)
 *           amounts = [0, 0, 0]
 * 
 *   Step 2: Set first element to input amount
 *           amounts[0] = amountIn
 *           amounts = [5, 0, 0]
 *                            ↑
 *           This is NOT a swap result.
 *           It represents the initial amount entering the first pool.
 * 
 * ============================================================================
 * 🔄 ITERATION #1 (i = 0): TokenA → TokenB
 * ============================================================================
 * 
 *   Current state: amounts = [5, 0, 0]
 * 
 *   Step 1: Identify the tokens for this swap
 *           path[i]     = path[0] = TokenA  (what we're selling)
 *           path[i + 1] = path[1] = TokenB  (what we're buying)
 * 
 *   ⚡ IMPORTANT: TokenB appears NOW, not after i++!
 *   We access it through path[i + 1], which is available immediately.
 *   We don't need i to become 1 to see TokenB.
 * 
 *   🧒 Analogy: Looking at a train map
 *   You're at Station 0 (TokenA). You look at the map and see:
 *   "My station = Station 0 (TokenA)"
 *   "Next station = Station 1 (TokenB)"
 *   You don't need to arrive at Station 1 to know it's TokenB!
 *   The map (path array) shows you right now!
 * 
 *   Step 2: Get reserves for THIS specific pair
 *           getReserves(factory, TokenA, TokenB)
 *           Returns from TokenA/TokenB Pool:
 *           reserveIn  = 100  (how many TokenA in the pool)
 *           reserveOut = 200  (how many TokenB in the pool)
 * 
 *   Step 3: Calculate output amount
 *           getAmountOut(amounts[i], reserveIn, reserveOut)
 *           getAmountOut(amounts[0], 100, 200)
 *           getAmountOut(5, 100, 200)
 *           Returns: 9 TokenB
 * 
 *   Step 4: Store the result
 *           amounts[i + 1] = 9
 *           amounts[1] = 9
 * 
 *   Array becomes: [5, 9, 0]
 *                  🟢  🔵  ❓
 *                TokenA TokenB TokenC
 *                (input) (just got!) (still unknown)
 * 
 * ============================================================================
 * 🔄 ITERATION #2 (i = 1): TokenB → TokenC
 * ============================================================================
 * 
 *   After i++, now i = 1
 *   Current state: amounts = [5, 9, 0]
 * 
 *   🔑 CRITICAL INSIGHT: Where did amounts[1] = 9 come from?
 *   - It was CREATED by iteration #1
 *   - It was not manually inserted by the user
 *   - It was not randomly generated by Solidity
 *   - It exists because the previous iteration calculated and stored it!
 * 
 *   This means the output of iteration #1 AUTOMATICALLY becomes 
 *   the input for iteration #2:
 * 
 *     Iteration #1: 5 TokenA → 9 TokenB
 *     Iteration #2: 9 TokenB → ? TokenC
 *                    ^ 
 *                    This value came from the amounts array!
 * 
 *   Step 1: Identify the tokens for this swap
 *           path[i]     = path[1] = TokenB  (what we're selling)
 *           path[i + 1] = path[2] = TokenC  (what we're buying)
 * 
 *   Step 2: Get reserves for the NEW pair
 *           getReserves(factory, TokenB, TokenC)
 *           Returns from TokenB/TokenC Pool:
 *           reserveIn  = 500  (how many TokenB in this different pool)
 *           reserveOut = 1000 (how many TokenC in this pool)
 * 
 *   Step 3: Calculate output using PREVIOUS output as input
 *           getAmountOut(amounts[i], reserveIn, reserveOut)
 *           getAmountOut(amounts[1], 500, 1000)
 *           getAmountOut(9, 500, 1000)
 *           Returns: 25 TokenC
 * 
 *   Step 4: Store the final result
 *           amounts[i + 1] = 25
 *           amounts[2] = 25
 * 
 *   Final array: [5, 9, 25]
 *                🟢  🔵  🟣
 *              TokenA TokenB TokenC
 *              (input) (middle) (final output!)
 * 
 * ============================================================================
 * 🏁 AFTER THE LOOP: The Complete Journey
 * ============================================================================
 * 
 *   Loop stops because i = 2 and condition is 2 < 2 (FALSE)
 * 
 *   🎯 Final Result: amounts = [5, 9, 25]
 * 
 *   ┌─────────────────────────────────────────────────────────┐
 *   │ 🚂 COMPLETE TRAIN JOURNEY:                               │
 *   │                                                          │
 *   │ STATIONS:   [TokenA]──────[TokenB]──────[TokenC]         │
 *   │               🚉            🚉            🚉              │
 *   │                                                          │
 *   │ PASSENGER:   5 TokenA      9 TokenB      25 TokenC       │
 *   │              (starts)      (swap 1)      (swap 2)        │
 *   │                                                          │
 *   │ JOURNEYS:   └── Swap 1 ──┘└── Swap 2 ──┘               │
 *   │              i=0            i=1                          │
 *   │                                                          │
 *   │ STORAGE:    amounts[0]=5   amounts[1]=9  amounts[2]=25   │
 *   │             (input)        (middle)      (final output)  │
 *   │                                                          │
 *   │ 🎓 amounts[1]=9 is BOTH:                                 │
 *   │    🏁 OUTPUT of swap 1                                   │
 *   │    🚀 INPUT for swap 2                                   │
 *   └─────────────────────────────────────────────────────────┘
 * 
 * ============================================================================
 * ✨ THE LOOP IN ONE SENTENCE
 * ============================================================================
 * 
 * "Each iteration takes the output from the previous iteration (or the 
 *  initial input), swaps it for the next token in the path, and stores the 
 *  result for the next iteration to use, until the final token is reached."
 * 
 * ============================================================================
 * 📝 KEY INSIGHTS SUMMARY
 * ============================================================================
 * 
 * 1. PATH VS SWAPS: N tokens = N-1 swaps = N-1 loop iterations
 *    Loop condition: i < path.length - 1 (not i < path.length!)
 * 
 * 2. IMMEDIATE ACCESS: path[i+1] gives you the next token NOW
 *    You don't wait for i++ to access the output token
 * 
 * 3. CHAINING: amounts[i+1] from swap i becomes amounts[i] for swap i+1
 *    The array connects iterations automatically
 * 
 * 4. PARALLEL ARRAYS: path[i] = WHAT token, amounts[i] = HOW MANY
 *    Same index, same step, different information
 * 
 * 5. PAIR RESERVES: Reserves belong to SPECIFIC PAIRS, not individual tokens
 *    The same token in different pairs has different reserve contexts
 * 
 * 6. INITIAL STATE: amounts[0] is NOT a swap output - it's user input
 *    Only amounts[1] onwards are calculated swap results
 * 
*/

    function getAmountsOut(address factory, uint256 inputAmount, address[] memory path)
        internal
        view 
        returns (uint256[] memory amounts)
    {
        if (path.length < 2) {
            //why this check? => because each swap universally will have 2 paths.  i.e WETH -> DAI , hence lenght 2 and index 1
            revert UV2Library__getAmountsOut__InvalidPath();
        }
        //  outputAmoutns length will be equal to path.lenth. ex WETH->DAI-LINK == [100, 20, 30] amoutn length will be 3 and path length will be 3 so we can use path.length to create amounts array
        amounts = new uint256[](path.length);
        /**
         * @dev Assigning the 0 index of amounts to the inputAmount. Note  This is because the first element of the amounts array represents the initial input amount for the first swap in the path.
         *The subsequent elements will be calculated based on the output of each swap.
         * @dev amounts[0] is not the result of a swap.
         */
        amounts[0] = inputAmount;


// go throught the Multi-Hop Swap Output Calculator before going below further ! Highly recommnded
 

        for(uint256 i; i < path.length - 1; i++) {
(uint256 reserveIn, reserveOut) = getReserves(factory, path[i], path[i + 1]);
amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }
/**
@dev This function basically does which token will be the first poisiion token between a pair like will token A be called token0 or tokenB will be called by caluclating the address, the token with the smaller address numerically will the the token0, and the other one token1
Keep in mind that tokenA doesnt mean it is token0, for naming conevention we wrote A .
@notice sortTokens doesn't just decide "which is token0."
It RETURNS both tokens in sorted order.

  token0 = the smaller address (always)
  token1 = the larger address (always)
  
It doesn't matter if you call them tokenA/tokenB, cat/dog, first/second.
The function always gives you: (smaller, larger) 
@dev FUNCTION FLOW - 
INPUT: tokenA = 0xBBB... , tokenB = 0xAAA...

Step 1: Are they different?
        0xBBB != 0xAAA? YES ✅

Step 2: Which is smaller?
        0xBBB < 0xAAA? NO ❌
        → Swap them!
        token0 = 0xAAA (smaller)
        token1 = 0xBBB (larger)

Step 3: Is token0 valid?
        0xAAA != address(0)? YES ✅

OUTPUT: token0 = 0xAAA , token1 = 0xBBB*/
    function sortTokens(address tokenA, address tokenB) internal pure returns(address token0, address token1) {
        if(tokenA == tokenB) {
            revert UV2Library__sortaTokens__Identical_Address();
            /** why revert if same address because - A pair needs TWO DIFFERENT tokens.
     You can't create a WETH/WETH pair. That would be trading a token with itself — makes no sense.
     🧒 Child Analogy:
You can't trade your Pikachu card for... another Pikachu card.
You need TWO DIFFERENT cards to trade!
     */

        }
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA)  
        /**It basically means if address of TokenA is smaller then address of tokenB then token 0 is TokenA and TokenB is token1 
        and if address of TokenB is smaller then address of tokenA then Token0 is TokenB and TokenA is Token1 as shown in Step 2 above. */
        if(token0 == address(0)) {
            revert UV2Library__sortTokens__Invalid_Token0_Address();
        }
/**
 * 
 * @dev VALIDATION ORDER: Why zero-address check is LAST, not first.
 * 
 *      It COULD be done at the front:
 *        if(tokenA == address(0)){revert .....};
 *        if(tokenA == address(0)){revert .....};
 *      This is correct but requires 2 checks.
 * 
 *      By sorting FIRST, we only need 1 check:
 *        After sorting: token0 < token1 (token0 is the smaller address).
 *        If token0 != 0 → since token1 > token0 → token1 != 0 automatically.
 * 
 *      Checking token0 alone covers both. Saves one require (saves gas).
 * 
 *      🧒 Analogy:
 *      You have two boxes. You put the smaller box on the left.
 *      You only open the left box. If it's not empty, the bigger
 *      right box can't be empty either. One check does the job of two.
 */

    }

/**
 * @notice Deterministically calculates the Uniswap V2 pair address for two tokens.
 *
 * @dev This function recreates Ethereum's CREATE2 address derivation formula
 *      used by the Factory when deploying a Pair contract.
 *
 *      The function DOES NOT:
 *      - Query the Factory
 *      - Read storage
 *      - Verify the pair exists
 *      - Perform any external calls
 *
 *      Instead, it mathematically predicts the address where the pair
 *      contract must exist (or will exist) based on:
 *
 *      1. Factory address      -> Who deploys the pair
 *      2. Salt                -> Which token pair is being deployed
 *      3. Init Code Hash      -> Which contract code is being deployed
 *
 *      CREATE2 Formula:
 *
 *      keccak256(
 *          0xff ++
 *          factory ++
 *          salt ++
 *          initCodeHash
 *      )
 *
 *      The salt is derived from:
 *
 *      keccak256(
 *          abi.encodePacked(token0, token1)
 *      )
 *
 *      where token0 is always the numerically smaller address and
 *      token1 is always the numerically larger address.
 *
 *      Sorting ensures:
 *
 *      WETH-USDC == USDC-WETH
 *
 *      resulting in one deterministic pair address regardless of
 *      input ordering.
 *
 *      IMPORTANT:
 *
 *      This function can calculate an address even if the pair
 *      contract has not been deployed yet.
 *
 *      Address prediction and contract existence are separate concepts.
 *
 * @param factory Address of the UniswapV2Factory contract.
 * @param tokenA First token of the pair (input order does not matter).
 * @param tokenB Second token of the pair (input order does not matter).
 *
 * @return pair Predicted address of the UniswapV2Pair contract.
 Note hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' is the byte code hashed by keccak256 , it is the byte code when we compile a contarct etc
 it is alo known as [Bytecode = creationCode = initCode] and if we hash like here we have the hashed value it becomes initCodeHash
 */
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns(address pair) {

        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint256(keccak256(abi.encodePacked(
            hex'ff'
            factory,
            keccak256(abi.encodePacked(token0, token1)) //salt
            //check natspec line after the return Pair line
            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' 
        ))));
    }
    function getReserves(address factory, address tokenA, address tokenB) internal view returns(uint256 reserveA, uint256 reserveB){
        (address token0,) = sortTokens(tokenA, tokenB);
      (uint256 reserve0, uint256 reserve1) = IUV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
      (reserveA, reserveB) = tokenA == token0? (reserve0, reserve1) : (reserve1, reserve0);
    }
}
