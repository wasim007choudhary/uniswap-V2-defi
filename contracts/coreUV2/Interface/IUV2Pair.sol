// SPDX-License-Identifeir: MIT

pragma solidity ^0.8.20;

interface IUV2Pair {
    function getReserves() external view returns (uint128 reserve0, uint128 reserve1, uint64 lastUpdatedTimeStamp);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}
