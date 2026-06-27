// SPDX-License-Identifeir: MIT

pragma solidity ^0.8.20;

interface IUV2Pair {
    function getReserves() external view returns (uint128 reserve0, uint128 reserve1, uint64 lastUpdatedTimeStamp);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function sync() external;
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
}
