//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*////////////////////////////////////////////////////////
                   IMPORTS
////////////////////////////////////////////////////////*/
import {IUV2Callee} from "contracts/coreUV2/Interface/IUV2Callee.sol";
import {IERC20} from "contracts/coreUV2/Interface/IERC20.sol";
import {IUV2Pair} from "contracts/coreUV2/Interface/IUV2Pair.sol";

import {UQ112xUQ112} from "contracts/coreUV2/library/UQ112x112.sol";

import {IUV2Factory} from "contracts/coreUV2/Interface/IUV2Factory.sol";
import {Math} from "contracts/coreUV2/library/Math.sol";

import {UniswapV2ERC20} from "contracts/coreUV2/UV2ERC20.sol";

contract UV2Pair is IUV2Pair, UniswapV2ERC20 {
    //  using UQ112xUQ112 for uint224; will do it in normal library call wont do this shit!
    /*///////////////////////////////////////////////////////
                                  STATE VARIABLES
    ////////////////////////////////////////////////////////*/
    uint112 private reserve0; // will use only single sotrage slot as the below 2 cobined will give 256 hence 1 storage slot i.e. 128+128+64 = 256
    uint112 private reserve1; // ^^^
    uint32 private timeStampLastUpdate; //  ^^^

    bool private islocked; // false by defaukt

    address public token0;
    address public token1;

    address public immutable i_factory;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    uint256 public ammKlastSnapshot;

    uint256 public constant MINIMUM_LIQUIDITY_LOCKED = 10 ** 3;

    /*////////////////////////////////////////////////////////
                       ERRORS
    ////////////////////////////////////////////////////////*/
    error UV2Pair___modifier__myReentryPrevention_ReentryPrevention();
    error UV2Pair___swap__InsufficientlIQUIDITYasInsuffientOutPutAmountInThePair();
    error UV2Pair___swap__InsufficientOutPutAmountInThePair();
    error UV2Pair___swap__InvalidAddressForSwapOutput();
    error UV2Pair___safeTransfer__TransferNotSuccessful();
    error UV2Pair___safeTransfer__TokenReturnDataError_TransferFailed();
    error UV2Pair___swap__NoTokensDepositedInThePair();
    error UV2Pair___swap__BrokeTheUniswapAMMconstantVariant__K();
    error UV2Pair___update__BalanceExceedsUint112duringDowncasting();
    error UV2Pair__initialize__OnlyFactoryCanCallInitialize_InvalidCaller();
    error UV2Pair__mint__ZeroLPTokensToMint();
    error UV2Pair___burn__InsufficientLiquidityBurned__and__ZeroTokensReturned();

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Prevents reentrancy attacks on protected functions.
     *
     * @dev Think of this as a temporary "Do Not Enter" sign.
     *
     *      When a protected function starts executing:
     *
     *          locked = true
     *
     *      Any attempt to enter the same protected function again before
     *      the current execution finishes will revert.
     *
     *      Example:
     *
     *          swap()
     *              ↓
     *          locked = true
     *              ↓
     *          external call
     *              ↓
     *          attacker tries swap() again
     *              ↓
     *          revert
     *
     *      Important:
     *
     *      This lock is NOT user-specific.
     *
     *      It does NOT mean:
     *
     *          User A is swapping
     *          ↓
     *          User B cannot swap
     *
     *      Ethereum already processes transactions one by one.
     *
     *      Instead, this modifier prevents nested execution paths inside
     *      the same transaction.
     *
     *      In simple words:
     *
     *          "A protected function cannot enter itself again before
     *           finishing its current execution."
     *
     *      Once execution completes:
     *
     *          locked = false
     *
     *      and future calls may proceed normally.
     *
     *      If execution reverts, EVM atomicity rolls back all state
     *      changes, including:
     *
     *          locked = true
     *
     *      Therefore the contract can never become permanently locked
     *      because of a reverted transaction.
     *
     * @custom:security My custom reentrancy guard that allows only one active execution of a protected function at a time.
     *  @dev Didn't use the OpenZeppelin ReentrancyGuard to save gas and keep the contract lightweight and also during uniswap v2 development, I wanted to implement my own reentrancy guard to understand the underlying mechanics and have more control over its behavior + oepenzeppelin was not available at that time/ widely used overall !
     */
    modifier myReentryPrevention() {
        if (islocked == true) {
            revert UV2Pair___modifier__myReentryPrevention_ReentryPrevention();
        }
        islocked = true;
        _;
        islocked = false;
    }

    /*///////////////////////////////////////////////////////
                   CONSTRUCTOR
     ///////////////////////////////////////////////////////*/
    constructor() {
        i_factory = msg.sender;
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    function initialize(address _token0, address _token1) external {
        if (msg.sender != i_factory) {
            revert UV2Pair__initialize__OnlyFactoryCanCallInitialize_InvalidCaller();
        }
        token0 = _token0;
        token1 = _token1;
    }
    /*///////////////////////////////////////////////////////
                  PUBLIC FUNCTIONS
     ///////////////////////////////////////////////////////*/

    /**
     * @notice Returns the Pair's last recorded reserves and reserve update timestamp.
     *
     * @dev Returns reserve0, reserve1, and blockTimestampLast directly from
     *      contract storage.
     *
     *      IMPORTANT:
     *
     *      reserve0 and reserve1 are the Pair's official accounting reserves,
     *      not necessarily the current ERC20 token balances held by the Pair.
     *
     *      Example:
     *
     *      reserve0 = 100 WETH
     *
     *      Someone directly transfers:
     *
     *      50 WETH
     *
     *      to the Pair contract.
     *
     *      Immediately afterwards:
     *
     *      balanceOf(pair) = 150 WETH
     *      reserve0        = 100 WETH
     *
     *      because reserves are only synchronized through functions such as
     *      swap(), mint(), burn(), and sync() which eventually call _update().
     *
     *      Token Relationships:
     *
     *      reserve0 ↔ token0
     *      reserve1 ↔ token1
     *
     *      Timestamp:
     *
     *      blockTimestampLast stores the timestamp of the last reserve
     *      synchronization and is later used by the protocol for
     *      time-weighted price calculations (TWAP).
     *
     *      Storage Packing:
     *
     *      uint112 reserve0
     *      uint112 reserve1
     *      uint32  blockTimestampLast
     *
     *      112 + 112 + 32 = 256 bits
     *
     *      allowing all three values to fit inside a single storage slot.
     *
     * @return _reserve0 Last recorded reserve for token0.
     * @return _reserve1 Last recorded reserve for token1.
     * @return _timeStampLastUpdate Timestamp of the most recent reserve update.
     */

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _timeStampLastUpdate) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _timeStampLastUpdate = timeStampLastUpdate;
    }

    /*///////////////////////////////////////////////////////
                   PRIVATE FUNCTIONS
      ///////////////////////////////////////////////////////*/
    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /**
     *  @dev  didnot useuswe MY WtrasferHelper here because here we will only use safe trasnfe and instead
     * of importing the whole library, we can just use the safe transfer function here directly to save gas and keep the contract lightweight.
     */
    function _safeTransfer(address token, address to, uint256 value) private {
        //bytes4(keccak256(bytes('transfer(address,uint256)'))) = 0xa9059cbb
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        if (!success) {
            revert UV2Pair___safeTransfer__TransferNotSuccessful();
        }
        if (data.length > 0 && !abi.decode(data, (bool))) {
            revert UV2Pair___safeTransfer__TokenReturnDataError_TransferFailed();
        }
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /**
     * @notice Synchronizes the Pair's internal state after balances have changed.
     * @dev This is the heart of the Pair's bookkeeping. It performs five major tasks:
     *
     * 1. Verifies that the latest ERC-20 balances can safely fit into the packed
     *    `uint112` reserve storage layout.
     *
     * 2. Computes the elapsed time since the previous update using a 32-bit circular
     *    timestamp. The subtraction intentionally wraps on overflow to correctly
     *    handle timestamp rollover.
     *
     * 3. Updates the cumulative price oracles (TWAP data) whenever:
     *      - time has elapsed, and
     *      - both reserves are non-zero.
     *
     *    The cumulative values are not the TWAP itself. They are continuously
     *    accumulated `price × time` values which external protocols later use to
     *    compute a Time-Weighted Average Price (TWAP) by comparing two snapshots.
     *
     * 4. Replaces the old stored reserves with the latest ERC-20 balances after all
     *    oracle calculations have completed.
     *
     * 5. Stores the new timestamp and emits a {Sync} event so off-chain applications,
     *    indexers, explorers and other protocols can observe the reserve update.
     *
     * @param _balance0 Current ERC-20 balance of token0 held by the Pair.
     *                  Retrieved via `IERC20(token0).balanceOf(address(this))`.
     *                  Kept as `uint256` because ERC-20 balances naturally return
     *                  `uint256`. Only after verifying that the value fits safely
     *                  into 112 bits is it downcast and stored as a reserve.
     *
     * @param _balance1 Current ERC-20 balance of token1 held by the Pair.
     *                  Behaves identically to `_balance0`.
     *
     * @param _reserve0 Previous stored reserve of token0.
     *                  Passed by the caller instead of being repeatedly read from
     *                  storage. This avoids additional expensive `SLOAD`
     *                  operations and guarantees every calculation inside this
     *                  function uses the same snapshot of the old reserves.
     *
     * @param _reserve1 Previous stored reserve of token1.
     *                  Behaves identically to `_reserve0`.
     *
     * @custom:gas The old reserves are loaded from storage once by the caller and
     * reused throughout this function, avoiding repeated `SLOAD` operations.
     *
     * @custom:oracle The cumulative price variables store running `price × time`
     * totals. They are designed for external TWAP consumers (lending protocols,
     * oracles, etc.) and do not represent the average price themselves.
     *
     * @custom:overflow Timestamp subtraction intentionally wraps around the
     * 32-bit clock. In Solidity 0.8+, this behavior requires an `unchecked`
     * block because arithmetic overflow otherwise reverts.
     *
     * @custom:see notes/UV2Pair/_update.md for complete dissection
     * @custom:see notes/Oracles/ - ALL OF THEM
     */
    function _update(uint256 _balance0, uint256 _balance1, uint112 _reserve0, uint112 _reserve1) private {
        if (_balance0 > type(uint112).max || _balance1 > type(uint112).max) {
            revert UV2Pair___update__BalanceExceedsUint112duringDowncasting();
        }
        /// if soldity earlier version or want be more vocal and intentional then wrtie uint32(block.timestamp % 2**32) below
        ///@custom:see notes/uint256 % 2**32 why , how it is done!, we are sol 8+ it it does autmatticaly for us
        uint32 blockTimestamp = uint32(block.timestamp);
        uint32 timeElasped;
        // modern solidity to desrie overflow we goota do unchecked or else it will revert
        unchecked {
            timeElasped = blockTimestamp - timeStampLastUpdate;
        }
        if (timeElasped > 0 && _reserve0 != 0 && _reserve1 != 0) {
            price0CumulativeLast += uint256(UQ112xUQ112.uqdiv(UQ112xUQ112.encode(_reserve1), _reserve0)) * timeElasped;
            price1CumulativeLast += uint256(UQ112xUQ112.uqdiv(UQ112xUQ112.encode(_reserve0), _reserve1)) * timeElasped;
        }
        _reserve0 = uint112(_balance0);
        _reserve1 = uint112(_balance1);
        timeStampLastUpdate = blockTimestamp;
        emit Sync(_reserve0, reserve1);
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /**
     * @notice Mints protocol LP tokens if protocol fees are enabled and the AMM's measured
     *         liquidity has increased since the last recorded snapshot.
     *
     * @dev This function implements Uniswap V2's protocol fee mechanism.
     *
     *      Workflow:
     *      1. Reads the protocol fee recipient (`feeTo`) from the Factory.
     *      2. Determines whether protocol fees are enabled (`protocolfeeOn`).
     *      3. Loads the previous AMM liquidity snapshot (`ammKlastSnapshot`).
     *      4. If protocol fees are enabled and a valid snapshot exists:
     *         - Computes the current liquidity metric: √(reserve0 × reserve1).
     *         - Computes the previous liquidity metric: √(ammKlastSnapshot).
     *         - If liquidity has grown, calculates the exact number of LP tokens
     *           the protocol should receive.
     *         - Mints those LP tokens to the protocol fee recipient.
     *      5. If protocol fees are disabled, clears the stored snapshot so that
     *         future protocol fee calculations start from a fresh baseline.
     *
     *      Protocol fees are **not** collected during swaps. Trading fees always
     *      remain inside the liquidity pool. This function merely recognizes the
     *      accumulated fee-generated liquidity growth and compensates the protocol
     *      by minting LP tokens that represent ownership of that growth.
     *
     *      The number of LP tokens minted is derived from:
     *
     *      liquidity =
     *      (totalSupply × (currentRootK - previousRootK))
     *      ------------------------------------------------
     *           (5 × currentRootK + previousRootK)
     *
     *      This formula ensures that, after minting increases `totalSupply`,
     *      the protocol owns exactly one-sixth of the fee-generated liquidity
     *      growth without removing any underlying assets from the pool.
     *
     *      If the calculated liquidity rounds down to zero due to Solidity's
     *      integer division, no LP tokens are minted. The accumulated fees
     *      remain inside the pool and may result in LP token minting during
     *      a future liquidity event once sufficient growth has accumulated.
     *
     *      When protocol fees are disabled, any existing AMM liquidity snapshot
     *      is discarded. This prevents the protocol from retroactively claiming
     *      fees that accumulated while protocol fee collection was turned off.
     *
     * @param _reserve0 The current stored reserve of token0 before reserve updates.
     * @param _reserve1 The current stored reserve of token1 before reserve updates.
     *
     * @return protocolfeeOn True if protocol fee collection is enabled; otherwise false.
     *
     * @custom:security Uses stored reserves rather than current token balances to
     *                  measure only fee-generated liquidity growth and exclude any
     *                  liquidity being added during the current transaction.
     *
     * @custom:security Mints protocol LP tokens before user LP tokens to ensure
     *                  newly added liquidity providers do not receive ownership
     *                  that belongs to the protocol.
     *
     * @custom:security Resets the AMM liquidity snapshot when protocol fees are
     *                  disabled to establish a new baseline if protocol fees are
     *                  enabled again in the future.
     *
     *  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     *  @custom:see For complete Dissection and a detailed breakdown visit:-
     *  notes/Liquidity/2. Code_Implementation/AddLiq_Mint/P4-Pair._mintFee , goodLuck, nw even a newbiew can get it with them notes I made-As I myself did ngl
     *  -------------------------------------------------------------------------------------------------------------------------------------------------------------------
     */

    function _mintProtocolFee(uint112 _reserve0, uint112 _reserve1) private returns (bool protocolfeeOn) {
        address protocolfeeOnAddress = IUV2Factory(i_factory).feeTo();
        protocolfeeOn = protocolfeeOnAddress != address(0);
        uint256 _ammKlastSnapshot = ammKlastSnapshot;
        if (protocolfeeOn) {
            uint256 currentAMMKroot = Math.squareRoot(uint256(_reserve0) * _reserve1);
            uint256 lastAMMKrootSnapshot = Math.squareRoot(_ammKlastSnapshot);
            if (currentAMMKroot > lastAMMKrootSnapshot) {
                uint256 numerator = totalSupply * (currentAMMKroot - lastAMMKrootSnapshot);
                uint256 denominator = 5 * currentAMMKroot + lastAMMKrootSnapshot;
                uint256 liquidity = numerator / denominator;
                if (liquidity > 0) {
                    _mint(protocolfeeOnAddress, liquidity);
                }
            }
        } else if (_ammKlastSnapshot != 0) {
            ammKlastSnapshot = 0;
        }
    }

    /*///////////////////////////////////////////////////////
                   EXTERNAL FUNCTIONS
      ///////////////////////////////////////////////////////*/
    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /**
     * @notice Mints LP tokens for newly deposited liquidity.
     *
     * @dev This function finalizes the liquidity addition process after the
     *      underlying tokens have already been transferred into the Pair contract.
     *
     *      High-level workflow:
     *
     *      1. Reads the previous pool reserves.
     *      2. Reads the Pair's current token balances.
     *      3. Determines how much token0 and token1 were deposited by comparing
     *         balances against the stored reserves.
     *      4. Recognizes and mints any pending protocol fee LP tokens (if enabled).
     *      5. Caches the updated total LP token supply.
     *      6. Determines whether this is:
     *         - the very first liquidity provider, or
     *         - an existing liquidity provider.
     *      7. Calculates the correct number of LP tokens to mint.
     *      8. Reverts if the calculated LP amount rounds down to zero.
     *      9. Mints the calculated LP tokens to the specified recipient.
     *     10. Updates the Pair's stored reserves to match the current balances.
     *     11. Records a new AMM liquidity snapshot (`ammKlastSnapshot`) when
     *         protocol fees are enabled.
     *     12. Emits a {Mint} event.
     *
     *      Initial Liquidity:
     *      - Uses the geometric mean: √(amount0 × amount1).
     *      - Permanently locks `MINIMUM_LIQUIDITY_LOCKED` LP tokens by minting
     *        them to the zero address.
     *
     *      Existing Liquidity:
     *      - Uses the proportional ownership formula based on the current
     *        reserves and total LP token supply.
     *
     *      This function does NOT transfer ERC-20 tokens from the liquidity
     *      provider. It assumes the required assets have already been transferred
     *      into the Pair contract before `mint()` is called.
     *
     * @param to The address that will receive the newly minted LP tokens.
     *
     * @return liquidity The number of LP tokens minted for the liquidity provider.
     *
     * @custom:reverts UV2Pair__mint__ZeroLPTokensToMint
     * Reverts if the deposited liquidity is too small to mint at least one LP
     * token after Solidity's integer rounding.
     *
     * @custom:security Protocol fee recognition occurs before LP minting so that
     *                  any protocol ownership is accounted for before calculating
     *                  the incoming liquidity provider's ownership.
     *
     * @custom:security The total LP token supply is cached only after protocol
     *                  fee minting because `_mintProtocolFee()` may increase
     *                  `totalSupply`.
     *
     * @custom:security Reserves are updated only after all minting operations
     *                  have completed, preventing newly deposited liquidity from
     *                  being mistaken for fee-generated liquidity growth.
     *  ------------------------------------------------------------------------------------------------------------------------------------------------------------------
     *  @custom:see For complete Dissection and a detailed breakdown visit:-
     *  notes/Liquidity/2. Code_Implementation/AddLiq_Mint/P5-Pair.Mint/p5.1-CompleteDissection.md
     *  ------------------------------------------------------------------------------------------------------------------------------------------------------------------
     *
     */
    function mint(address to) external myReentryPrevention returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        bool protocolFeeOn = _mintProtocolFee(_reserve0, _reserve1);

        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee

        if (_totalSupply == 0) {
            liquidity = Math.squareRoot(amount0 * amount1) - MINIMUM_LIQUIDITY_LOCKED;
            _mint(address(0), MINIMUM_LIQUIDITY_LOCKED); // permanently lock the first MINIMUM_LIQUIDITY_LOCKED tokens
        } else {
            liquidity = Math.minOfTwo(amount0 * _totalSupply / _reserve0, amount1 * _totalSupply / _reserve1);
        }
        if (liquidity == 0) {
            revert UV2Pair__mint__ZeroLPTokensToMint();
        }
        _mint(to, liquidity);
        _update(balance0, balance1, _reserve0, _reserve1);
        if (protocolFeeOn) {
            ammKlastSnapshot = uint256(reserve0) * reserve1;
        }
        emit Mint(msg.sender, amount0, amount1);
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /**
     * @notice Burns LP tokens held by this Pair contract and returns the corresponding underlying assets.
     * @dev This function is the inverse of {mint}. It assumes the LP tokens to be burned have already
     *      been transferred to the Pair contract (typically by the Router via `transferFrom`).
     *
     *      Execution flow:
     *      1. Reads the previous reserve snapshot.
     *      2. Reads the Pair's current token balances.
     *      3. Determines the amount of LP tokens currently held by the Pair.
     *      4. Mints protocol fee LP tokens if protocol fees are enabled.
     *      5. Calculates the proportional share of Token0 and Token1 owed to the liquidity provider.
     *      6. Reverts if either redemption amount is zero.
     *      7. Burns the Pair's LP tokens, permanently removing them from circulation.
     *      8. Transfers the underlying tokens to the recipient.
     *      9. Updates reserves to match the Pair's new balances.
     *      10. Updates the protocol fee snapshot (`ammKlastSnapshot`) when protocol fees are enabled.
     *      11. Emits a {Burn} event.
     *
     *      The redemption amounts are calculated using the Pair's current token balances instead of
     *      stored reserves to ensure every liquidity provider receives their fair proportional
     *      (pro-rata) share of the Pair's actual holdings at redemption time.
     *
     * @param to The address that will receive the redeemed Token0 and Token1.
     *
     * @return amount0 The amount of Token0 redeemed and transferred to `to`.
     * @return amount1 The amount of Token1 redeemed and transferred to `to`.
     *
     * @custom:requirements
     * - The Pair contract must already own the LP tokens to be burned.
     * - Both calculated redemption amounts must be greater than zero.
     *
     * @custom:reverts UV2Pair___burn__InsufficientLiquidityBurned__and__ZeroTokensReturned
     * Reverts if either `amount0` or `amount1` is zero, preventing LP tokens from being burned while
     * returning an insignificant or zero amount of one or both underlying assets.
     *
     * @custom:emits Burn
     * Emits a {Burn} event containing the caller, redeemed Token0 amount, redeemed Token1 amount,
     * and the recipient address.
     * ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     * @custom:see For complete Dissection and a detailed breakdown visit:-notes/Liquidity/2. Code_Implementation/RemoveLiq_Burn/3. Pair Burn
     */

    function burn(address to) external myReentryPrevention returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();

        address _token0 = token0;
        address _token1 = token1;
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];
        bool protocolFeeOn = _mintProtocolFee(_reserve0, _reserve1);

        uint256 _totalSupply = totalSupply;

        amount0 = liquidity * balance0 / _totalSupply;
        amount1 = liquidity * balance1 / _totalSupply;

        if (amount0 == 0 || amount1 == 0) {
            revert UV2Pair___burn__InsufficientLiquidityBurned__and__ZeroTokensReturned();
        }

        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);

        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        _update(balance0, balance1, _reserve0, _reserve1);

        if (protocolFeeOn) {
            ammKlastSnapshot = uint256(reserve0) * reserve1;
        }

        emit Burn(msg.sender, amount0, amount1, to);
    }
    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /**
     *
     * @notice Executes a token swap while enforcing the fee-adjusted
     * constant-product invariant.
     *
     *  @dev The Pair does not trust the Router, caller, or swap direction.
     * Instead it reconstructs reality from reserve snapshots and current
     * token balances, verifies payment was received, applies the 0.3% fee,
     * enforces the fee-adjusted K invariant, synchronizes reserves, and
     * emits a Swap event.
     *
     * @dev Flow:
     * * Verify output amounts.
     * * Verify available liquidity.
     * * Optimistically transfer outputs.
     * * Execute flash swap callback (if applicable).
     * * Measure actual balances.
     * * Reconstruct input amounts.
     * * Verify payment was received.
     * * Enforce the fee-adjusted constant-product invariant (K).
     * * Synchronize reserves through _update.
     * * Emit the Swap event.
     *
     * Router calculates.
     * Pair enforces.
     *
     * @param amount0out Amount of token0 to send out of the Pair.
     * @param amount1out Amount of token1 to send out of the Pair.
     * @param to Recipient of the output tokens.
     * @param data Arbitrary callback data used for flash swaps.
     *
     * @custom:invariant
     * After accounting for the 0.3% swap fee:
     *
     * balance0Adjusted * balance1Adjusted
     * ```
     *   >=
     *   ```
     * reserve0 * reserve1 * 1000^2
     *
     * This guarantees that the Pair's constant-product invariant cannot
     * be violated and that value cannot be extracted from the pool without
     * providing sufficient input tokens.
     *
     * @custom:reverts
     * Reverts if:
     * * No output amount is requested.
     * * Insufficient liquidity exists.
     * * Output tokens are sent to a token contract.
     * * No input tokens are received.
     * * The fee-adjusted invariant (K) would be violated.
     *
     *  @custom:see for Complete dissection and detialed q/a see: notes/Core/UV2Pair--swap.md
     *
     * @custom:see for _update: see  notes/Core/UV2Pair--update.md
     * For a detailed breakdown of reserve synchronization, timestamp updates,
     * cumulative price tracking, oracle accounting, and TWAP preparation.
     */

    function swap(uint256 amount0out, uint256 amount1out, address to, bytes calldata data)
        external
        myReentryPrevention
    {
        if (amount0out <= 0 && amount1out <= 0) {
            revert UV2Pair___swap__InsufficientOutPutAmountInThePair();
        }
        (uint112 reserve_0, uint112 reserve_1,) = getReserves();
        if (amount0out >= reserve0 || amount1out >= reserve1) {
            revert UV2Pair___swap__InsufficientlIQUIDITYasInsuffientOutPutAmountInThePair();
        }
        uint256 balance0;
        uint256 balance1;
        // to prevent stack too deep eror i.e {} we used here
        {
            address _token0 = token0;
            address _token1 = token1;

            if (to == _token0 || to == _token1) {
                revert UV2Pair___swap__InvalidAddressForSwapOutput();
            }
            if (amount0out > 0) {
                _safeTransfer(_token0, to, amount0out);
            }
            if (amount1out > 0) {
                _safeTransfer(_token1, to, amount1out);
            }
            if (data.length > 0) {
                IUV2Callee(to).uniswapV2Call(msg.sender, amount0out, amount1out, data);
            }
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }

        uint256 amount0in = balance0 > reserve_0 - amount0out ? balance0 - (reserve_0 - amount0out) : 0;
        uint256 amount1in = balance1 > reserve_1 - amount1out ? balance1 - (reserve_1 - amount1out) : 0;

        if (amount0in <= 0 && amount1in <= 0) {
            revert UV2Pair___swap__NoTokensDepositedInThePair();
        }
        // to prevent stack too deep eror i.e {} we used here
        {
            uint256 balance0Adjusted = (balance0 * 1000) - (amount0in * 3);
            uint256 balance1Adjusted = (balance1 * 1000) - (amount1in * 3);
            if ((balance0Adjusted * balance1Adjusted) < (uint256(reserve_0) * uint256(reserve_1)) * 1000 ** 2) {
                revert UV2Pair___swap__BrokeTheUniswapAMMconstantVariant__K();
            }
        }
        _update(balance0, balance1, reserve_0, reserve_1);
        emit Swap(msg.sender, amount0in, amount1in, amount0out, amount1out, to);
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /**
     * @notice Transfers any excess Token0 and Token1 held by the Pair to a specified recipient.
     * @dev Compares the Pair's current token balances against the recorded reserves and transfers
     *      only the surplus (`balance - reserve`) for each token.
     *
     *      This function is intended for recovering tokens that were transferred directly to the
     *      Pair contract without going through the normal liquidity workflow (e.g., accidental
     *      transfers, dust, or unexpected excess tokens).
     *
     *      Unlike {sync}, this function does **not** update the reserves. Instead, it removes the
     *      excess tokens so that the Pair's balances once again match the stored reserve snapshot.
     *
     *      Anyone may call this function. The recovered excess tokens are sent to the address
     *      specified by `to`.
     *
     * @param to The address that will receive any excess Token0 and Token1.
     *
     * @custom:requirements
     * - The Pair's current balance for each token must be greater than or equal to its recorded reserve.
     *
     * @custom:emits
     * Does not emit a dedicated event. Token transfers emit the standard ERC-20 `Transfer` events.
     *
     * --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     * @custom:see Visit-notes/Core/UV2Pair--skim.md for complete breakdown! GGs
     * --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     */
    function skim(address to) external myReentryPrevention {
        address _token0 = token0;
        address _token1 = token1;
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)) - reserve0);
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)) - reserve1);
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    /**
     * @notice Forces the Pair's stored reserves to match its current ERC-20 balances.
     *
     * @dev Reads the actual token balances held by the Pair contract and commits
     * them as the new reserves by calling {_update()}.
     *
     * This function is useful when tokens are transferred directly to the Pair
     * contract without going through `mint()`, `burn()`, or `swap()`. In those
     * situations, the ERC-20 balances change, but the stored reserves remain
     * outdated until `sync()` is called.
     *
     * Internally this function:
     * - Reads the current `token0` balance.
     * - Reads the current `token1` balance.
     * - Passes the previous reserves and current balances into {_update()}.
     * - Updates the TWAP oracle if time has elapsed.
     * - Synchronizes the stored reserves with reality.
     * - Emits a {Sync} event.
     *
     * Protected by the `lock` modifier to prevent reentrant state updates.
     *
     * @custom:gas The previous reserves are passed directly to {_update()}
     * instead of being read again from storage, avoiding redundant `SLOAD`
     * operations.
     *
     * @custom:see {_update}
     */
    function sync() external myReentryPrevention {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    /*-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
    // didnt want to name the function I_Factory in the interface in order to match so here you go;
    function factory() external view returns (address) {
        return i_factory;
    }
}
