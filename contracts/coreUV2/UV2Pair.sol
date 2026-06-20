//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract UV2Pair {

////////////////////////////////////////////////////////
                   STATE VARIABLES
////////////////////////////////////////////////////////
uint128 reserve0;  // will use only single sotrage slot as the below 2 cobined will give 256 hence 1 storage slot i.e. 128+128+64 = 256
uint128 reserve1;   // ^^^
uint64 timeStampLastUpdate; //  ^^^


////////////////////////////////////////////////////////
                 PUBLIC FUNCTIONS
 ///////////////////////////////////////////////////////
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
 * @return _blockTimestampLast Timestamp of the most recent reserve update.
 */
function getReserves() public view returns(uint128 _reserve0, uint128 _reserve1, uint64 _timeStampLastUpdate) {
_reserve0 = reserve0;
_reserve1 = reserve1
_timeStampLastUpdate = timeStampLastUpdate; 
}
}