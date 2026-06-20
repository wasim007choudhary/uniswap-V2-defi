// SPDX-License-Identifeir: MIT

pragma soldiity ^0.8.20;

interface IUV2Pair {
    function getReserves() public view returns(uint128 reserve0, uint128 reserve1, uint64 lastUpdatedTimeStamp);
}