// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IUV2Factory {
    function feeTo() external view returns (address);
    function feeToAddressSetter() external view returns (address);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}
