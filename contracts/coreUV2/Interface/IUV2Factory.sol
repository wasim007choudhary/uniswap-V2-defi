// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IUV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 totalPairsNow);

    function feeTo() external view returns (address);
    function feeToAddressSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address _feeTo) external;
    function SetFeeToAddressSetter(address _feeToAddressSetter) external;
}
