//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract UV2Pair {
    /*////////////////////////////////////////////////////////
                       ERRORS
    ////////////////////////////////////////////////////////*/
    error UV2Pair___modifier__myReentryPrevention_ReentryPrevention();

    /*///////////////////////////////////////////////////////
                       STATE VARIABLES
    ////////////////////////////////////////////////////////*/
    uint128 reserve0; // will use only single sotrage slot as the below 2 cobined will give 256 hence 1 storage slot i.e. 128+128+64 = 256
    uint128 reserve1; // ^^^
    uint32 timeStampLastUpdate; //  ^^^

    bool private islocked; // false by defaukt

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
    function getReserves() public view returns (uint128 _reserve0, uint128 _reserve1, uint32 _timeStampLastUpdate) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _timeStampLastUpdate = timeStampLastUpdate;
    }

    function swap(uint256 amount0out, uint256 amount1out, address to, bytes calldata data) external {}
}
