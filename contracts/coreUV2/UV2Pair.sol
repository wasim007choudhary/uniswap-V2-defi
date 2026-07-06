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

contract UV2Pair is IUV2Pair {
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
     * @custom:see notes/UV2Pair/_update.md
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

    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool protocolfeeOn) {
        address protocolfeeOnAddress = IUV2Factory(i_factory).feeTo();
        protocolfeeOn = protocolfeeOnAddress != address(0);
        uint256 _ammKlastSnapshot = ammKlastSnapshot;
        if (protocolfeeOn) {
            uint256 currentAMMKroot = Math.squareRoot(uint256(_reserve0) * _reserve1);
            uint256 lastAMMKrootSnapshot = Math.squareRoot(_ammKlastSnapshot);
            if (currentAMMKroot > lastAMMKrootSnapshot) {}
        } else if (_ammKlastSnapshot != 0) {
            ammKlastSnapshot = 0;
        }
    }

    function mint(address to) external returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;
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

    function swap(uint256 amount0out, uint256 amount1out, address to, bytes calldata data) external {
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
