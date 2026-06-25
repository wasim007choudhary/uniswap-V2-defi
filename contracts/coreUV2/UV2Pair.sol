//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*////////////////////////////////////////////////////////
                   IMPORTS
////////////////////////////////////////////////////////*/
import {IUV2Callee} from "contracts/coreUV2/Interface/IUV2Callee.sol";
import {IERC20} from "contracts/coreUV2/Interface/IERC20.sol";
import {IUV2Pair} from "contracts/coreUV2/Interface/IUV2Pair.sol";

contract UV2Pair is IUV2Pair {
    /*///////////////////////////////////////////////////////
                                  STATE VARIABLES
    ////////////////////////////////////////////////////////*/
    uint112 reserve0; // will use only single sotrage slot as the below 2 cobined will give 256 hence 1 storage slot i.e. 128+128+64 = 256
    uint112 reserve1; // ^^^
    uint32 timeStampLastUpdate; //  ^^^

    bool private islocked; // false by defaukt

    address public token0;
    address public token1;

    address public immutable i_factory;

    uint256 public price0CumulativeLast;

    /*////////////////////////////////////////////////////////
                       EVENTS
    ////////////////////////////////////////////////////////*/
    event swap(
        address indexed sender,
        uint256 amount0out,
        uint256 amount0in,
        uint256 amount1out,
        uint256 amount1in,
        address indexed to
    );
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

    function _update(uint256 _balance0, uint256 _balance1, uint112 _reserve0, uint112 _reserve1) private {
        if (_balance0 > type(uint112).max || _balance1 > type(uint112).max) {
            revert UV2Pair___update__BalanceExceedsUint112duringDowncasting();
        }
        /// if soldity earlier version or want be more vocal and intentional then wrtie uint32(block.timestamp % 2**32) below
        ///@custom:see notes/uint256 % 2**32 why , how it is done!, we are sol 8+ it it does autmatticaly for us
        uint32 blockTimestamp = uint32(block.timestamp);
        uint32 timeElaspedSinceLastUpdate;
        unchecked {
            timeElaspedSinceLastUpdate = blockTimestamp - timeStampLastUpdate;
        }
        if (timeElaspedSinceLastUpdate > 0 && _reserve0 != 0 && _reserve1 != 0) {}
    }

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
        (uint128 reserve_0, uint128 reserve_1,) = getReserves();
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
        //_updatenow next line will route us to _update which we will disection next,
        emit swap(msg.sender, amount0out, amount0in, amount1out, amount1in, to);
    }
}
